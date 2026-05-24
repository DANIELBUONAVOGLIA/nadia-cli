CREATE TABLE IF NOT EXISTS conversation_history (
  id SERIAL PRIMARY KEY,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  embedding vector(1536),
  created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS memory_chunks (
  id SERIAL PRIMARY KEY,
  source TEXT,
  content TEXT NOT NULL,
  embedding vector(1536),
  metadata JSONB
);
CREATE TABLE IF NOT EXISTS memory_facts (
  id SERIAL PRIMARY KEY,
  fact TEXT NOT NULL,
  embedding vector(1536),
  created_at TIMESTAMP DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS transcript_chunks (
  id SERIAL PRIMARY KEY,
  source_call TEXT,
  content TEXT NOT NULL,
  embedding vector(1536)
);
CREATE INDEX IF NOT EXISTS idx_conv_emb ON conversation_history USING hnsw (embedding vector_cosine_ops);
CREATE INDEX IF NOT EXISTS idx_mem_emb ON memory_chunks USING hnsw (embedding vector_cosine_ops);
CREATE INDEX IF NOT EXISTS idx_facts_emb ON memory_facts USING hnsw (embedding vector_cosine_ops);
CREATE INDEX IF NOT EXISTS idx_trans_emb ON transcript_chunks USING hnsw (embedding vector_cosine_ops);
