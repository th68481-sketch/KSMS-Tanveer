import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { corsHeaders } from '../_shared/cors.ts'

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const { token, title, body } = await req.json()

  const FCM_PROJECT_ID = Deno.env.get('FCM_PROJECT_ID')
  const FCM_ACCESS_TOKEN = Deno.env.get('FCM_ACCESS_TOKEN') // Assume token is refreshed/managed

  const response = await fetch(`https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${FCM_ACCESS_TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token,
        notification: { title, body }
      }
    }),
  })

  const data = await response.json()
  
  return new Response(JSON.stringify(data), { status: response.status, headers: corsHeaders })
})
