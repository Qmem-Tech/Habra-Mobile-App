-- Legal content pages editable in Super Admin and rendered in mobile app.
-- Run with: supabase db push

create table if not exists public.legal_content_pages (
  slug text primary key,
  title text not null,
  html_content text not null,
  updated_at timestamptz not null default now()
);

alter table public.legal_content_pages enable row level security;

drop policy if exists "Anyone can read legal content pages"
  on public.legal_content_pages;
create policy "Anyone can read legal content pages"
  on public.legal_content_pages
  for select
  using (true);

drop policy if exists "Admins can insert legal content pages"
  on public.legal_content_pages;
create policy "Admins can insert legal content pages"
  on public.legal_content_pages
  for insert
  with check (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

drop policy if exists "Admins can update legal content pages"
  on public.legal_content_pages;
create policy "Admins can update legal content pages"
  on public.legal_content_pages
  for update
  using (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  )
  with check (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

drop policy if exists "Admins can delete legal content pages"
  on public.legal_content_pages;
create policy "Admins can delete legal content pages"
  on public.legal_content_pages
  for delete
  using (
    exists (
      select 1
      from public.profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

insert into public.legal_content_pages (slug, title, html_content, updated_at)
values
  (
    'terms_of_service',
    'Terms of Service',
    '<p>The Habesha Community Super App provides a unified platform for the Ethiopian and Eritrean diaspora to connect with local businesses, events, and job opportunities. By using the app, you agree to the following:</p><h2>Eligibility</h2><ul><li>You must be at least 18 years old to post business listings or job opportunities.</li><li>One account per user. Duplicate or fake profiles used to manipulate ratings or community chats may be suspended.</li></ul><h2>Service Mechanics</h2><ul><li>Business Directory: Users can browse and contact local services. The app is a directory and is not responsible for the quality of services provided by third parties.</li><li>Job Board: Employers are responsible for the accuracy of job descriptions. The app does not vet individual applicants or employers.</li><li>Events: Users can discover and purchase tickets for community concerts, cultural holidays, and social gatherings.</li></ul><h2>Ticketing and Payments</h2><ul><li>All ticket purchases are processed securely via Stripe.</li><li>Refund policies are determined by the individual event promoter.</li></ul><h2>Privacy and Data</h2><ul><li>Your payment data is handled by Stripe and is never stored on our private servers.</li><li>Refer to our full Privacy Policy for details on how we protect community data.</li></ul>',
    now()
  ),
  (
    'privacy_policy',
    'Privacy Policy',
    '<p>Your privacy is important to us. This Privacy Policy explains how the Habesha Community Super App collects, uses, and protects your personal information.</p><h2>Information We Collect</h2><ul><li>Account info: name, email address, phone number, and city selection.</li><li>Business info: details for businesses and jobs you publish.</li><li>Usage data: in-app activity used to improve the product.</li></ul><h2>How We Use Your Information</h2><ul><li>Localization: provide content based on your city.</li><li>Service delivery: process purchases and account capabilities.</li><li>Security: detect fraud and policy violations.</li></ul><h2>Payments and Financial Security</h2><ul><li>Transactions are processed securely via Stripe.</li><li>We do not store full card or bank account details.</li></ul><h2>Sharing Information</h2><ul><li>We do not sell personal data.</li><li>Limited sharing occurs only for platform operations, legal compliance, and trusted service providers.</li></ul><h2>Your Rights</h2><ul><li>You can request access, correction, or deletion of your personal information.</li></ul>',
    now()
  )
on conflict (slug) do nothing;
