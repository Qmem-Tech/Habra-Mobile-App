-- Lets users remove their own unpaid event orders from My Tickets.
--
-- The mobile app's `Remove` button calls the `cancel_unpaid_event_order` RPC
-- defined below. The RPC runs with SECURITY DEFINER so it can bypass RLS for
-- the actual UPDATE while still enforcing two invariants in SQL:
--   - the order belongs to the caller (auth.uid())
--   - the order is in a removable state (pending / processing / failed)
--
-- An UPDATE policy is also added as a defence-in-depth fallback for any code
-- path that still does a direct UPDATE on `orders`.

alter table public.orders enable row level security;

drop policy if exists "Users cancel their own unpaid orders" on public.orders;
create policy "Users cancel their own unpaid orders"
  on public.orders for update
  using (
    user_id = auth.uid()
    and status::text in ('pending', 'processing', 'failed')
  )
  with check (
    user_id = auth.uid()
    and status::text in ('pending', 'processing', 'failed', 'cancelled')
  );

----------------------------------------------------------------------
-- RPC: cancel_unpaid_event_order
-- Called by the mobile app's My Tickets "Remove" button. Server-side so the
-- UPDATE happens with elevated privileges and we can return precise error
-- codes the client can show to the user.
--
-- Returns the number of rows updated (0 on race / already cancelled, 1 on
-- success). All comparisons cast `orders.status` to text so the function works
-- whether the column is `text`, `varchar(...)`, or a custom enum.
----------------------------------------------------------------------
drop function if exists public.cancel_unpaid_event_order(uuid);
create function public.cancel_unpaid_event_order(p_order_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_current_status text;
  v_rows integer := 0;
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;

  select o.status::text
    into v_current_status
    from public.orders o
   where o.id = p_order_id
     and o.user_id = v_user_id;

  if v_current_status is null then
    raise exception 'order_not_found_or_not_yours' using errcode = 'P0002';
  end if;

  if v_current_status not in ('pending', 'processing', 'failed') then
    raise exception 'order_not_removable:%' , v_current_status
      using errcode = 'P0003';
  end if;

  update public.orders o
     set status = 'cancelled'
   where o.id = p_order_id
     and o.user_id = v_user_id
     and o.status::text in ('pending', 'processing', 'failed');

  get diagnostics v_rows = row_count;
  return v_rows;
end;
$$;

grant execute on function public.cancel_unpaid_event_order(uuid) to authenticated;
