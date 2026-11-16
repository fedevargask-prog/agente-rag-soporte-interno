-- Ejecutar en el SQL Editor de Supabase (o en tu Postgres self-hosted con pgvector)
create extension if not exists vector;

create table if not exists documents (
  id bigserial primary key,
  content text,
  metadata jsonb,
  embedding vector(768)  -- nomic-embed-text = 768 dimensiones
);

create or replace function match_documents (
  query_embedding vector(768),
  match_count int default null,
  filter jsonb default '{}'
) returns table (id bigint, content text, metadata jsonb, similarity float)
language plpgsql as $$
#variable_conflict use_column
begin
  return query
  select id, content, metadata,
         1 - (documents.embedding <=> query_embedding) as similarity
  from documents
  where metadata @> filter
  order by documents.embedding <=> query_embedding
  limit match_count;
end;
$$;

create index if not exists documents_embedding_idx
  on documents using hnsw (embedding vector_cosine_ops);
