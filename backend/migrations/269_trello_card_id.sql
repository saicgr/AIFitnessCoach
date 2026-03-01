-- Add trello_card_id to support_tickets for syncing ticket ↔ Trello card
ALTER TABLE support_tickets
ADD COLUMN IF NOT EXISTS trello_card_id TEXT;

-- Index for lookup when syncing replies/close events
CREATE INDEX IF NOT EXISTS idx_support_tickets_trello_card_id
ON support_tickets (trello_card_id)
WHERE trello_card_id IS NOT NULL;
