import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'jsr:@supabase/supabase-js'
import { corsHeaders } from '../_shared/cors.ts'
import { checkAdminRole } from '../_shared/authz.ts'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response('Missing authorization header', { status: 401, headers: corsHeaders })
  }

  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)
  
  if (authError || !user) {
    return new Response('Invalid token', { status: 401, headers: corsHeaders })
  }

  if (!(await checkAdminRole(supabaseClient, user.id))) {
    return new Response('Forbidden', { status: 403, headers: corsHeaders })
  }

  const { email, tenantId, campusId } = await req.json()

  // Transaction-like operations
  const { data, error } = await supabaseClient.rpc('approve_access_request_tx', {
    p_email: email,
    p_tenant_id: tenantId,
    p_campus_id: campusId,
    p_admin_id: user.id
  })

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500, headers: corsHeaders })
  }

  // Invite user
  await supabaseClient.auth.admin.inviteUserByEmail(email)

  // Log audit event
  await supabaseClient.from('audit_events').insert({
    actor_id: user.id,
    action: 'approve_access_request',
    target: email,
    metadata: { tenantId, campusId }
  })

  return new Response(JSON.stringify({ message: 'Access approved' }), { status: 200, headers: corsHeaders })
})
