drop function if exists public.claim_prescription(text, text);

create function public.claim_prescription(
  p_rx_code text,
  p_pharmacy text
)
returns table (
  ok boolean,
  errcode text,
  errmsg text,
  prescription jsonb
)
language plpgsql
security definer
as $$
declare
  v_candidate public.prescriptions%rowtype;
  v_updated   public.prescriptions%rowtype;
begin
  ok := false;
  errcode := null;
  errmsg := null;
  prescription := null;

  select *
  into v_candidate
  from public.prescriptions
  where rx_code = p_rx_code
  order by created_at desc
  limit 1;

  if not found then
    insert into public.claims_audit (rx_code, pharmacy, prescription_id, result, errcode, message)
    values (p_rx_code, p_pharmacy, null, 'NOT_FOUND', 'P1001', 'Prescription code not found');

    ok := false;
    errcode := 'P1001';
    errmsg := 'Prescription code not found';
    return next; return;
  end if;

  if v_candidate.expires_at is not null and v_candidate.expires_at < now() then
    insert into public.claims_audit (rx_code, pharmacy, prescription_id, result, errcode, message)
    values (p_rx_code, p_pharmacy, v_candidate.id, 'EXPIRED', 'P1002', 'Prescription has expired');

    ok := false;
    errcode := 'P1002';
    errmsg := 'Prescription has expired';
    prescription := to_jsonb(v_candidate);
    return next; return;
  end if;

  if v_candidate.claimed_at is not null then
    insert into public.claims_audit (rx_code, pharmacy, prescription_id, result, errcode, message)
    values (p_rx_code, p_pharmacy, v_candidate.id, 'ALREADY_CLAIMED', 'P1003', 'Prescription already claimed');

    ok := false;
    errcode := 'P1003';
    errmsg := 'Prescription already claimed';
    prescription := to_jsonb(v_candidate);
    return next; return;
  end if;

  update public.prescriptions
  set
    status = 'CLAIMED',
    claimed_by = p_pharmacy,
    claimed_at = now()
  where id = v_candidate.id
    and claimed_at is null
    and (expires_at is null or expires_at >= now())
  returning *
  into v_updated;

  if not found then
    select * into v_candidate
    from public.prescriptions
    where id = v_candidate.id;

    insert into public.claims_audit (rx_code, pharmacy, prescription_id, result, errcode, message)
    values (p_rx_code, p_pharmacy, v_candidate.id, 'ALREADY_CLAIMED', 'P1003', 'Claim blocked (concurrent claim or late expiry)');

    ok := false;
    errcode := 'P1003';
    errmsg := 'Prescription already claimed';
    prescription := to_jsonb(v_candidate);
    return next; return;
  end if;

  insert into public.claims_audit (rx_code, pharmacy, prescription_id, result, errcode, message)
  values (p_rx_code, p_pharmacy, v_updated.id, 'SUCCESS', null, 'Claim successful');

  ok := true;
  errcode := null;
  errmsg := null;
  prescription := to_jsonb(v_updated);
  return next; return;
end;
$$;
