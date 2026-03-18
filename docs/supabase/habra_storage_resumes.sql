-- Create the resumes storage bucket and policies for job application uploads.
-- Run this in Supabase Dashboard → SQL Editor if resume upload fails with permission errors.
--
-- Path structure: {user_id}/{job_id}/{timestamp}.{ext}
-- Users can only upload to their own folder (first path segment = auth.uid()).

-- 1. Create the bucket (if it doesn't exist)
insert into storage.buckets (id, name, public, file_size_limit)
values (
  'resumes',
  'resumes',
  false,
  5242880  -- 5MB
)
on conflict (id) do update set
  file_size_limit = excluded.file_size_limit;

-- 2. Allow authenticated users to INSERT their own resumes (path: user_id/job_id/file.ext)
drop policy if exists "resumes_insert_own" on storage.objects;
create policy "resumes_insert_own"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'resumes'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- 3. Allow authenticated users to SELECT (read) resumes
--    Applicants can read their own; employers need to read for job applications.
drop policy if exists "resumes_select" on storage.objects;
create policy "resumes_select"
on storage.objects for select
to authenticated
using (bucket_id = 'resumes');
