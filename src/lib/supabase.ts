import 'react-native-url-polyfill/auto';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { AppState, Platform } from 'react-native';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';

// Publishable key is intentionally PUBLIC; never embed secret/service_role keys.
// Before real users, deploy SQL migrations and finish access/security review.
const url = process.env.EXPO_PUBLIC_SUPABASE_URL;
const publishableKey = process.env.EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
export const supabaseIsConfigured = Boolean(url && publishableKey);

export const supabase: SupabaseClient | null = supabaseIsConfigured
  ? createClient(url!, publishableKey!, {
      auth: {
        ...(Platform.OS === 'web' ? {} : { storage: AsyncStorage }),
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: false,
      },
    })
  : null;

if (supabase && Platform.OS !== 'web') {
  const client = supabase;
  AppState.addEventListener('change', state => {
    if (state === 'active') client.auth.startAutoRefresh();
    else client.auth.stopAutoRefresh();
  });
}
