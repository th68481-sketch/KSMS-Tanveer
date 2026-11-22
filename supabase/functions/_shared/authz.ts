import { createClient } from 'jsr:@supabase/supabase-js'

export const checkAdminRole = async (supabaseAdmin: any, userId: string): Promise<boolean> => {
  const { data, error } = await supabaseAdmin
    .from('user_roles')
    .select('role')
    .eq('user_id', userId)
    .in('role', ['platform_admin', 'gov_admin'])
    .single()

  return !error && !!data
}
