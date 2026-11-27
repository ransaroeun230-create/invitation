# Portal setup (login · admin · customer)

Pages: `login.html` (Google / GitHub / email sign-in & sign-up), `admin.html` (admin only), `customer.html` (each customer's own invitations).

1. Create a Supabase project (supabase.com) and run `supabase.sql` in SQL Editor.
2. Put the Project URL and anon key in `config.js`.
3. Supabase → Authentication → URL Configuration: Site URL = your site (e.g. `https://ransaroeun230-create.github.io/invitation/portal/login.html`); add the same under Redirect URLs.
4. Google: Google Cloud Console → OAuth client (Web). Authorized redirect URI = `https://YOUR-PROJECT.supabase.co/auth/v1/callback`. Paste Client ID/Secret in Supabase → Authentication → Providers → Google.
5. GitHub: github.com → Settings → Developer settings → OAuth Apps → New. Callback URL = the same Supabase callback URL. Paste Client ID/Secret in Providers → GitHub.
6. Sign in once with your account, then run in SQL Editor: `update public.profiles set role='admin' where email='YOUR_EMAIL';`
