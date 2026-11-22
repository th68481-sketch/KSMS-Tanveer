import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'jsr:@supabase/supabase-js'
import { corsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
  )

  const { operation_uuid, records } = await req.json()

  // 1. Check idempotency
  const { data: existingOp } = await supabaseClient
    .from('sync_operations')
    .select('id')
    .eq('operation_uuid', operation_uuid)
    .single()

  if (existingOp) {
    return new Response(JSON.stringify({ status: 'already_processed' }), { status: 200, headers: corsHeaders })
  }

  // 2. Process records (simplified conflict detection logic)
  const conflicts = []
  for (const record of records) {
    const { data: currentRecord } = await supabaseClient
      .from('attendance_records')
      .select('version')
      .eq('id', record.id)
      .single()

    if (currentRecord && currentRecord.version >= record.version) {
      conflicts.push(record)
    }
  }

  if (conflicts.length > 0) {
    return new Response(JSON.stringify({ status: 'conflict', conflicts }), { status: 409, headers: corsHeaders })
  }

  // 3. Upsert
  for (const record of records) {
    await supabaseClient.from('attendance_records').upsert(record)
  }

  // 4. Log operation
  await supabaseClient.from('sync_operations').insert({ operation_uuid, status: 'processed' })

  return new Response(JSON.stringify({ status: 'success' }), { status: 200, headers: corsHeaders })
})
