# 🛒 E-commerce API (Carrinho de Compras)

API em Ruby on Rails para gerenciamento de carrinho de compras, com documentação via Swagger (RSwag), testes em RSpec, execução via Docker Compose e job de abandono de carrinho com Sidekiq.

---

## 🔍 Visão Geral
- Carrinho por sessão com operações de adicionar, listar, alterar quantidade e remover produtos.
- Documentação disponível em http://localhost:3000/api-docs.
- Banco: PostgreSQL; Cache/filas: Redis; Background jobs: Sidekiq.

## 🛠 Tecnologias
- Ruby 3.3.1
- Rails 7.1.3.2
- PostgreSQL 16
- Redis 7
- Sidekiq 7
- RSpec e `FactoryBot
- RuboCop
- RSwag (API Docs)
- Docker e `Docker Compose

## 🏗 Arquitetura
- Controllers: regras de API (CartsController, ProductsController).
- Services`: lógica de domínio (CartService).
- Serializers: contratos de resposta (CartSerializer, CartItemSerializer`, `ProductSerializer).
- Jobs: MarkCartAsAbandonedJob usando Sidekiq Scheduler (config: config/schedule.yml).

## ⚙️ Requisitos
- Docker e Docker Compose instalados.
- Opcional: Ruby/Bundler local para rodar fora de container.

## 🚀 Subir com Docker Compose
1️⃣ Verificar variáveis de ambiente (.env)
- Ajuste conforme necessário:
  - `POSTGRES_USER`, `POSTGRES_PASSWORD`, `DB_PORT`
  - `REDIS_PORT`, `REDIS_URL`
  - `RAILS_BIND`, `RAILS_PORT`, `WEB_PORT`
  - `RAILS_ENV_DEV`, `RAILS_ENV_TEST`
  - `DATABASE_URL_DEV`, `DATABASE_URL_TEST`
- Valide interpolação: docker compose config

2️⃣ Subir serviços base
```bash
docker compose up -d db redis
```
- Checar status/logs: `docker compose ps` e `docker compose logs -f db`

3️⃣ Preparar banco (primeira execução)
```bash
docker compose run --rm web rails db:create db:migrate
````
- Popular dados (opcional):
```bash
docker compose run --rm web rails db:seed
```

4️⃣ Subir aplicação e workers
```bash
docker compose up -d web` (sobe db e redis)
docker compose up -d sidekiq` (opcional, para jobs)
```

5️⃣ Acessos:
- API: http://localhost:3000
- Swagger UI: http://localhost:3000/api-docs
- Sidekiq UI: http://localhost:3000/sidekiq

⚠️ Observações (Windows/PowerShell): evite usar `&&` em um único comando; execute os comandos separadamente ou use `;` apenas quando suportado.

## 🖥 Rodar sem Docker (opcional)
```bash
bundle install
bundle exec rails db:prepare
bundle exec rails server
bundle exec sidekiq (para jobs)
```

## 📚 Documentação da API (Swagger/RSwag)
- UI: http://localhost:3000/api-docs
- Geração do arquivo: swagger/v1/swagger.yaml
- Para regerar a documentação via specs:
```bash
docker compose run --rm test rails rswag:specs:swaggerize
```

⚠️ Nota: há política de cobertura 100% via `SimpleCov`. A tarefa de geração roda em modo `--dry-run` e pode sair com código não-zero por cobertura, apesar de gerar o arquivo corretamente.

## 🧩 Endpoints Principais
- GET /cart — lista itens do carrinho atual.
- POST /cart/add_item` — adiciona item ou altera quantidade (payload: product_id, quantity).
- DELETE /cart/:product_id` — remove item do carrinho.
- GET /products e GET /products/:id — produtos.

## 🧪 Testes
- Rodar suíte de testes:
```bash
docker compose --profile test run --rm test
```

Cobertura:
- Relatório em coverage/. Política atual exige 100% (.simplecov).

## ✨ Qualidade de Código
- Rodar RuboCop:
```bash
docker compose run --rm web rubocop
```

## 🗄 Banco de Dados
- Preparar/migrar: 
```bash
docker compose run --rm web rails db:prepare
```
- Migrar:
```bash
docker compose run --rm web rails db:migrate
```
- Seeds:
```bash
docker compose run --rm web rails db:seed
```

## ⚡Background Jobs
- Subir Sidekiq: docker compose up -d sidekiq
- UI: http://localhost:3000/sidekiq
- Agendamentos: `config/schedule.yml (marcar carrinhos como abandonados após 3h e remover após 7 dias).

## 🛠 Configuração
- Variáveis via `.env` (carregadas pelo Compose):
  - Banco: 
    - POSTGRES_USER
    - POSTGRES_PASSWORD
    - DB_PORT
    - DATABASE_URL_DEV
    - DATABASE_URL_TEST
  - Redis: 
    - REDIS_PORT
    - REDIS_URL
  - App: 
    - RAILS_BIND
    - RAILS_PORT
    - WEB_PORT
    - RAILS_ENV_DEV
    - RAILS_ENV_TEST
- Observação: config/database.yml usa host, port, username, password das envs para development e test.
