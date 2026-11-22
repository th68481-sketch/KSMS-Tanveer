# Karachi School Management System (KSMS)

Complete, multi-tenant school management system built with Flutter and Supabase.

## Prerequisites
- Flutter SDK (3.24.5+)
- Supabase CLI

## Setup
1. `flutter pub get`
2. `flutter pub run build_runner build`
3. `supabase init` (if not done)
4. Update `.env` with your project keys.
5. Push migrations: `supabase db push`
6. Deploy functions: `supabase functions deploy`
7. Bootstrap: `./scripts/bootstrap.sh <email> <password> <setup_token>`

## Deployment
- Frontend: `flutter build web`
- Backend: Supabase manages PostgreSQL, Edge Functions, Auth, and Storage automatically.
