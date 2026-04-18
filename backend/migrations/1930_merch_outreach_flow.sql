-- ============================================================================
-- Migration 1930: Simplify merch claim flow to "we'll reach out to you"
-- ============================================================================
-- Instead of collecting shipping addresses in-app, users just accept the
-- reward and we email them later when ready to ship. Cleaner UX, no address
-- rot, ops team collects details via email/CRM when they actually ship.
--
-- Changes:
--   - Add 'awaiting_outreach' status
--   - New RPC: accept_merch_claim(claim_id, user_id)
-- ============================================================================

-- Widen status check constraint to include 'awaiting_outreach'
ALTER TABLE merch_claims DROP CONSTRAINT IF EXISTS merch_claims_status_check;
ALTER TABLE merch_claims
  ADD CONSTRAINT merch_claims_status_check
  CHECK (status IN (
    'pending_address',
    'awaiting_outreach',
    'address_submitted',
    'shipped',
    'delivered',
    'cancelled'
  ));


-- ============================================================================
-- RPC: accept a merch claim (transitions pending_address → awaiting_outreach)
-- ----------------------------------------------------------------------------
-- Ops will contact the user via email to collect shipping details when they
-- are ready to fulfill the order.
-- ============================================================================
CREATE OR REPLACE FUNCTION accept_merch_claim(p_claim_id UUID, p_user_id UUID)
RETURNS merch_claims
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_claim merch_claims;
BEGIN
  SELECT * INTO v_claim FROM merch_claims
  WHERE id = p_claim_id AND user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Merch claim not found for user';
  END IF;

  IF v_claim.status NOT IN ('pending_address', 'awaiting_outreach') THEN
    RAISE EXCEPTION 'Claim is % and cannot be accepted', v_claim.status;
  END IF;

  UPDATE merch_claims
  SET status = 'awaiting_outreach',
      address_submitted_at = COALESCE(address_submitted_at, NOW())
  WHERE id = p_claim_id
  RETURNING * INTO v_claim;

  RETURN v_claim;
END;
$$;

GRANT EXECUTE ON FUNCTION accept_merch_claim(UUID, UUID) TO authenticated, service_role;

COMMENT ON FUNCTION accept_merch_claim IS
'Migration 1930: User accepts a merch reward. Ops will reach out via email to collect shipping details when ready to ship.';
