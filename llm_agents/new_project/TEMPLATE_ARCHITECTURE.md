# Enterprise Next.js Application Template - Architecture Guide

**Version:** 1.0
**Last Updated:** 2026-01-25
**Reference Implementation:** HISCOXNDS (Hiscox Netting Down System)

---

## Purpose of This Document

This guide provides architectural patterns, technology decisions, and design principles for building enterprise-grade Next.js applications. It draws from proven patterns in production systems (particularly HISCOXNDS) while presenting options and trade-offs to help teams make informed decisions.

**This is NOT prescriptive** - it presents multiple approaches with their pros and cons. Teams should evaluate options based on their specific context.

---

## Table of Contents

1. [Technology Stack Decisions](#technology-stack-decisions)
2. [Architectural Patterns](#architectural-patterns)
3. [Database Architecture](#database-architecture)
4. [API Design](#api-design)
5. [Authentication & Authorization](#authentication--authorization)
6. [State Management](#state-management)
7. [Testing Strategy](#testing-strategy)
8. [Security Architecture](#security-architecture)
9. [Deployment Architecture](#deployment-architecture)
10. [Optional Services](#optional-services)

---

## Technology Stack Decisions

### Frontend Framework: Next.js

**Why Next.js:**
- ✅ Full-stack React framework (UI + API in one codebase)
- ✅ App Router with React Server Components (latest patterns)
- ✅ Built-in optimizations (image optimization, code splitting)
- ✅ Excellent TypeScript support
- ✅ Large ecosystem and community

**Alternative Considerations:**

| Framework | When to Use | Trade-offs |
|-----------|-------------|------------|
| **Next.js** (Recommended) | Full-stack apps, SEO important, need SSR | More opinionated, some learning curve |
| **Remix** | Prefer web standards, nested routing | Smaller ecosystem, less tooling |
| **Vite + React** | SPA only, no SSR needed | Client-side only, separate API needed |
| **SvelteKit** | Performance critical, smaller bundles | Smaller community, fewer libraries |

**HISCOXNDS Example:** Uses Next.js 14.1.0 with App Router successfully for full-stack insurance application.

---

### Language: TypeScript

**Non-negotiable recommendation:** Use TypeScript for enterprise applications.

**Benefits:**
- ✅ Catch errors at compile time
- ✅ Better IDE support and refactoring
- ✅ Self-documenting code via types
- ✅ Required for end-to-end type safety

**Configuration:**
```json
// tsconfig.json - Strict mode recommended
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true
  }
}
```

---

### Package Manager: pnpm

**Why pnpm:**
- ✅ Fastest install times (shared dependency store)
- ✅ Strict dependency resolution (prevents phantom dependencies)
- ✅ Disk space efficient
- ✅ Monorepo support

**Alternatives:**

| Tool | Pros | Cons |
|------|------|------|
| **pnpm** (Recommended) | Fast, strict, efficient | Less common in tutorials |
| **npm** | Default, universal | Slower, less strict |
| **yarn** | Good monorepo support | Berry version has breaking changes |
| **bun** | Very fast | Still maturing, smaller ecosystem |

**HISCOXNDS Example:** Uses pnpm 8.x successfully.

---

## Architectural Patterns

### Overall Architecture Style

**Recommended:** Modular Monolith with Optional Microservices

```
┌─────────────────────────────────────────┐
│         Next.js Monolith                │
│  ┌─────────┬─────────┬────────────┐    │
│  │   UI    │   API   │  Business  │    │
│  │  Layer  │  Layer  │   Logic    │    │
│  └─────────┴─────────┴────────────┘    │
│           │                              │
│      ┌────▼─────┐                       │
│      │ Database │                       │
│      └──────────┘                       │
└─────────────────────────────────────────┘
         │
         │ Optional
         ▼
┌─────────────────┐
│ External Service│ (Heavy computation,
│ (R, Python, etc)│  special requirements)
└─────────────────┘
```

**Why Modular Monolith:**
- ✅ Simpler deployment and operations
- ✅ Easier local development
- ✅ Lower infrastructure cost
- ✅ Can extract services later if needed
- ✅ Shared types and validation

**When to Use Microservices:**
- Different language required (e.g., R for actuarial calcs, Python for ML)
- Different scaling requirements
- Team autonomy requirements
- Legacy system integration

**HISCOXNDS Example:** Monolith (Next.js) + Microservice (R Plumber for calculations). R service handles domain-specific graph algorithms that would be complex in JavaScript.

---

### Separation of Concerns

**Layer Structure:**

```
app/                    # Presentation Layer (Routes & Layouts)
├── (auth)/            # Route groups for organization
├── (dashboard)/
└── api/

components/             # UI Components Layer
├── [domain]/          # Domain-specific components
└── ui/                # Shared UI primitives

lib/                    # Business Logic & Infrastructure
├── api/               # Data Access Layer
│   ├── [domain]/
│   │   ├── queries.ts     # Read operations
│   │   └── mutations.ts   # Write operations
├── db/                # Database Layer
│   ├── schema/        # Table definitions
│   ├── migrations/    # SQL migrations
│   └── index.ts       # Connection management
├── server/            # Server-Side Logic
│   ├── routers/       # API route handlers
│   └── middleware/    # Auth, validation, etc.
└── validation/        # Shared validation schemas
```

**Key Principles:**

1. **Domain-Driven Organization** (Not technical layers)
   - ✅ `api/products/`, `api/orders/`
   - ❌ `controllers/`, `services/`, `repositories/`

2. **Colocation** - Related files together
   ```
   products/
   ├── schema.ts          # Database schema
   ├── api/queries.ts     # Data access
   ├── api/mutations.ts
   ├── router.ts          # API routes
   └── components/        # UI components
   ```

3. **Clear Boundaries**
   - UI ↔ API: Type-safe API layer (tRPC) or OpenAPI
   - API ↔ Database: ORM (Drizzle, Prisma)
   - Client ↔ Server: Server Components vs Client Components

**HISCOXNDS Example:** Clean separation with 30+ domain routers, each following consistent query/mutation pattern.

---

### Design Patterns in Use

#### 1. Repository Pattern
**Purpose:** Abstract data access from business logic

```typescript
// lib/api/products/queries.ts
export const getProducts = async () => {
  return await db.select().from(products)
}

export const getProductById = async (id: string) => {
  return await db.select()
    .from(products)
    .where(eq(products.id, id))
    .limit(1)
}

// lib/api/products/mutations.ts
export const createProduct = async (data: NewProduct) => {
  return await db.insert(products).values(data).returning()
}
```

**Benefits:**
- ✅ Reusable across multiple API routes
- ✅ Easy to test (mock the repository)
- ✅ Consistent data access patterns
- ✅ Can add caching layer without changing callers

#### 2. Schema-Driven Development
**Purpose:** Single source of truth for types, validation, and database

```typescript
// Step 1: Define database schema (Drizzle)
export const products = pgTable('products', {
  id: uuid('id').primaryKey(),
  name: varchar('name', { length: 256 }).notNull(),
  price: real('price').notNull(),
})

// Step 2: Generate Zod schemas
export const insertProductSchema = createInsertSchema(products)

// Step 3: Add validation rules
export const insertProductParams = insertProductSchema.extend({
  name: z.string().min(1).max(256),
  price: z.number().positive(),
})

// Step 4: Derive TypeScript types
export type Product = typeof products.$inferSelect
export type NewProduct = z.infer<typeof insertProductParams>
```

**Benefits:**
- ✅ Change schema once, types update everywhere
- ✅ Runtime validation + compile-time safety
- ✅ Database, API, and UI stay in sync
- ✅ Automatic API documentation via types

**HISCOXNDS Example:** All 30 tables follow this pattern. Change a schema field and TypeScript errors guide you to update all dependent code.

#### 3. Provider Pattern
**Purpose:** Inject dependencies and context

```typescript
// app/layout.tsx
export default function RootLayout({ children }) {
  return (
    <html>
      <body>
        <AuthProvider>        {/* Clerk, NextAuth, etc. */}
          <TRPCProvider>      {/* API client */}
            <StateProvider>   {/* Jotai, Zustand, etc. */}
              <ThemeProvider> {/* Dark/light mode */}
                {children}
              </ThemeProvider>
            </StateProvider>
          </TRPCProvider>
        </AuthProvider>
      </body>
    </html>
  )
}
```

**Order matters:** Auth → API (needs auth context) → State → Theme

#### 4. Middleware Pattern
**Purpose:** Cross-cutting concerns (auth, logging, validation)

```typescript
// Authentication middleware
const isAuthed = middleware(({ ctx, next }) => {
  if (!ctx.userId) {
    throw new Error('Unauthorized')
  }
  return next({ ctx: { userId: ctx.userId } })
})

// Logging middleware
const withLogging = middleware(({ ctx, next, path }) => {
  logger.info({ path, userId: ctx.userId }, 'API call')
  return next({ ctx })
})

// Compose middleware
export const protectedProcedure = publicProcedure
  .use(isAuthed)
  .use(withLogging)
```

---

## Database Architecture

### Database Choice

**Recommended:** PostgreSQL

**Why PostgreSQL:**
- ✅ ACID compliant, battle-tested
- ✅ Rich type system (JSON, arrays, enums)
- ✅ Excellent JSON support (JSONB)
- ✅ Full-text search
- ✅ Robust extension ecosystem
- ✅ Great performance at scale

**Alternatives:**

| Database | When to Use | Trade-offs |
|----------|-------------|------------|
| **PostgreSQL** (Recommended) | Most use cases, relational data | More complex than simple KV stores |
| **MySQL/MariaDB** | Team expertise, lower resource usage | Fewer features than Postgres |
| **MongoDB** | Truly schemaless, document-heavy | No ACID transactions (before 4.0), harder to query relationships |
| **SQLite** | Simple apps, edge computing | Limited concurrency, no distributed |
| **PlanetScale** | MySQL with vitess, scale out | Vendor lock-in, costs |

**Cloud Options:**

| Option | Pros | Cons |
|--------|------|------|
| **Neon** | Serverless Postgres, auto-scaling, free tier | Newer service |
| **Supabase** | Postgres + auth + storage | Opinionated stack |
| **RDS** | Managed by AWS, reliable | More expensive, less auto-scaling |
| **Railway** | Simple deployment, good DX | Smaller scale |

**HISCOXNDS Example:** PostgreSQL 15 (local Docker) with Neon serverless option via environment variable.

---

### ORM Choice

**Recommended:** Drizzle ORM

**Why Drizzle:**
- ✅ TypeScript-first with excellent DX
- ✅ SQL-like syntax (familiar to SQL developers)
- ✅ Zero runtime overhead
- ✅ Great tree-shaking (smaller bundles)
- ✅ Works well with schema-driven development

**Comparison:**

| ORM | Pros | Cons |
|-----|------|------|
| **Drizzle** (Recommended for new projects) | Lightweight, SQL-like, TypeScript-first | Smaller community, fewer examples |
| **Prisma** | Large community, great tooling, migrations | Heavier runtime, proprietary schema language |
| **TypeORM** | Mature, decorators pattern | Less active, legacy feel |
| **Kysely** | Type-safe SQL builder, minimal | More verbose, no migration tools |

**Example Comparison:**

```typescript
// Drizzle (SQL-like, explicit)
const products = await db
  .select()
  .from(productsTable)
  .where(eq(productsTable.category, 'electronics'))
  .orderBy(desc(productsTable.price))

// Prisma (more abstract)
const products = await prisma.product.findMany({
  where: { category: 'electronics' },
  orderBy: { price: 'desc' },
})
```

**HISCOXNDS Example:** Drizzle ORM 0.28.6 with schema-driven approach across 30+ tables.

---

### Schema Design Patterns

#### Pattern 1: Temporal/Audit Fields

**Every table should track:**

```typescript
export const baseFields = {
  // Temporal tracking
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),

  // Audit tracking
  createdBy: varchar('created_by', { length: 32 }).notNull(),
  updatedBy: varchar('updated_by', { length: 32 }),

  // Approval workflow (if needed)
  status: statusEnum('status').notNull().default('draft'),
  approvedBy: varchar('approved_by', { length: 32 }),
  approvedAt: timestamp('approved_at'),
}

export const products = pgTable('products', {
  id: uuid('id').primaryKey(),
  name: varchar('name', { length: 256 }).notNull(),
  ...baseFields,
})
```

**Benefits:**
- ✅ Complete audit trail
- ✅ Compliance ready (GDPR, SOX, HIPAA)
- ✅ Debugging (when did this change?)
- ✅ Workflow support (draft → approved)

**HISCOXNDS Example:** Every table includes `timeStamp`, `operationType`, `approvalStatus`, `approvedBy`, `approvedAt`, `clerkUserId`.

#### Pattern 2: Separate Audit Logs Table

**For complete change history:**

```typescript
export const auditLogs = pgTable('audit_logs', {
  id: serial('id').primaryKey(),
  tableName: varchar('table_name').notNull(),
  recordId: uuid('record_id').notNull(),
  operation: varchar('operation').notNull(), // INSERT, UPDATE, DELETE
  changedAt: timestamp('changed_at').notNull().defaultNow(),
  changedBy: varchar('changed_by').notNull(),

  // JSONB for flexible before/after storage
  originalValues: jsonb('original_values'),
  newValues: jsonb('new_values').notNull(),
})
```

**Implemented via database triggers:**

```sql
CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (table_name, record_id, operation, changed_by, original_values, new_values)
  VALUES (TG_TABLE_NAME, NEW.id, TG_OP, NEW.updated_by, row_to_json(OLD), row_to_json(NEW));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER products_audit
  AFTER INSERT OR UPDATE OR DELETE ON products
  FOR EACH ROW EXECUTE FUNCTION audit_trigger();
```

**HISCOXNDS Example:** Dedicated `audit_logs` table with JSONB for complete change tracking.

#### Pattern 3: Soft Deletes vs Hard Deletes

**Option A: Soft Deletes (Recommended for compliance)**

```typescript
export const products = pgTable('products', {
  id: uuid('id').primaryKey(),
  deletedAt: timestamp('deleted_at'),  // NULL = active, timestamp = deleted
})

// Query only active records
const activeProducts = await db
  .select()
  .from(products)
  .where(isNull(products.deletedAt))
```

**Option B: Status Enum (More flexible)**

```typescript
export const recordStatus = pgEnum('record_status', [
  'active',
  'archived',
  'deleted',
])

export const products = pgTable('products', {
  status: recordStatus('status').notNull().default('active'),
})
```

**HISCOXNDS Example:** Uses `operationType` enum with 'DELETE' status rather than separate deletedAt field.

#### Pattern 4: JSONB for Flexible Data

**Use JSONB for:**
- ✅ Settings/configuration
- ✅ Metadata that varies by record
- ✅ Audit logs (before/after state)
- ❌ NOT for queryable business data (use columns instead)

```typescript
export const users = pgTable('users', {
  id: uuid('id').primaryKey(),
  email: varchar('email').notNull(),

  // Flexible settings
  preferences: jsonb('preferences').$type<{
    theme: 'light' | 'dark'
    notifications: boolean
    language: string
  }>(),

  // Typed metadata
  metadata: jsonb('metadata').$type<Record<string, unknown>>(),
})
```

**Querying JSONB:**
```typescript
// Find users with dark theme
const darkModeUsers = await db
  .select()
  .from(users)
  .where(sql`${users.preferences}->>'theme' = 'dark'`)
```

---

### Migration Strategy

**Recommended:** Version-controlled SQL migrations

**Why:**
- ✅ Explicit control over schema changes
- ✅ Review-able in PRs
- ✅ Rollback capability
- ✅ Production-safe

**Tools:**

| Tool | Approach | Best For |
|------|----------|----------|
| **Drizzle Kit** (with Drizzle) | Generate from schema changes | TypeScript-first projects |
| **Prisma Migrate** (with Prisma) | Generate from schema changes | Prisma users |
| **Flyway** | Hand-written SQL migrations | Java ecosystems, complex migrations |
| **Liquibase** | XML/YAML migrations | Enterprise, multi-DB |
| **node-pg-migrate** | JavaScript migrations | Simple needs |

**Drizzle Kit Workflow:**

```bash
# 1. Edit schema file
# lib/db/schema/products.ts - add new column

# 2. Generate migration
pnpm drizzle-kit generate

# 3. Review generated SQL
# lib/db/migrations/0001_add_description.sql

# 4. Apply migration
pnpm drizzle-kit migrate

# 5. Commit both schema and migration
git add lib/db/schema/products.ts lib/db/migrations/
git commit -m "Add description column to products"
```

**Best Practices:**
- ✅ Never edit applied migrations
- ✅ Always review generated SQL before applying
- ✅ Test migrations on staging first
- ✅ Include rollback migrations for complex changes
- ❌ Never use `db push` in production (dev only)

**HISCOXNDS Example:** Drizzle Kit migrations with explicit SQL files tracked in git.

---

## API Design

### API Style Choice

**Three Main Options:**

#### Option 1: tRPC (Recommended for TypeScript monoliths)

**When to use:**
- ✅ Full-stack TypeScript project
- ✅ Frontend and backend in same repo
- ✅ Internal APIs (not public)
- ✅ Want end-to-end type safety

**Pros:**
- ✅ No code generation or API versioning needed
- ✅ Autocomplete for API calls
- ✅ Compile-time error checking
- ✅ Automatic request/response validation

**Cons:**
- ❌ TypeScript/JavaScript clients only
- ❌ Not suitable for public APIs
- ❌ Smaller ecosystem than REST

**Example:**

```typescript
// Server
export const productsRouter = router({
  list: publicProcedure.query(async () => {
    return await db.select().from(products)
  }),

  create: protectedProcedure
    .input(insertProductParams)
    .mutation(async ({ input }) => {
      return await db.insert(products).values(input)
    }),
})

// Client - fully typed!
const products = await trpc.products.list.query()
const newProduct = await trpc.products.create.mutate({
  name: 'Widget',
  price: 29.99,
})
```

**HISCOXNDS Example:** Uses tRPC 10.43.1 across 30+ routers with complete type safety.

#### Option 2: REST (Traditional, widely understood)

**When to use:**
- ✅ Public APIs
- ✅ Multi-language clients
- ✅ Need HTTP caching
- ✅ Team familiar with REST

**Pros:**
- ✅ Universal standard
- ✅ HTTP caching built-in
- ✅ Any client can consume
- ✅ Mature tooling

**Cons:**
- ❌ Manual type definitions
- ❌ API versioning needed
- ❌ No compile-time safety
- ❌ Boilerplate for validation

**Example with Next.js Route Handlers:**

```typescript
// app/api/products/route.ts
import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  const products = await db.select().from(productsTable)
  return NextResponse.json(products)
}

export async function POST(request: NextRequest) {
  const body = await request.json()

  // Manual validation
  const parsed = insertProductParams.parse(body)

  const product = await db.insert(productsTable).values(parsed)
  return NextResponse.json(product, { status: 201 })
}
```

**With OpenAPI/Swagger for types:**
```bash
# Generate TypeScript client from OpenAPI spec
pnpm openapi-typescript api-spec.yaml -o types/api.ts
```

#### Option 3: GraphQL (Flexible queries)

**When to use:**
- ✅ Complex data requirements
- ✅ Mobile apps (reduce over-fetching)
- ✅ Multiple frontend teams
- ✅ Need fine-grained permissions

**Pros:**
- ✅ Clients request exactly what they need
- ✅ Single endpoint
- ✅ Strong typing
- ✅ Real-time subscriptions

**Cons:**
- ❌ Steeper learning curve
- ❌ More complex server setup
- ❌ Caching more difficult
- ❌ Can have N+1 query problems

**Example with Pothos:**

```typescript
import SchemaBuilder from '@pothos/core'

const builder = new SchemaBuilder({})

builder.queryType({
  fields: (t) => ({
    products: t.field({
      type: [Product],
      resolve: () => db.select().from(products),
    }),
  }),
})
```

**Decision Matrix:**

| Criteria | tRPC | REST | GraphQL |
|----------|------|------|---------|
| Type Safety | ⭐⭐⭐⭐⭐ | ⭐⭐ (with OpenAPI) | ⭐⭐⭐⭐ |
| Public API | ❌ | ✅ | ✅ |
| Learning Curve | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| Ecosystem | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Flexibility | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Setup Time | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ |

---

### API Organization

**Recommended Structure:**

```
lib/server/routers/
├── _app.ts              # Master router (aggregates all)
├── products.ts          # Product CRUD
├── orders.ts            # Order management
├── users.ts             # User management
└── admin.ts             # Admin operations
```

**Each router follows CRUD pattern:**

```typescript
export const productsRouter = router({
  // Queries (reads)
  list: protectedProcedure.query(async () => { ... }),
  getById: protectedProcedure.input(idSchema).query(async ({ input }) => { ... }),

  // Mutations (writes)
  create: protectedProcedure.input(createSchema).mutation(async ({ input }) => { ... }),
  update: protectedProcedure.input(updateSchema).mutation(async ({ input }) => { ... }),
  delete: protectedProcedure.input(idSchema).mutation(async ({ input }) => { ... }),
})
```

**Master router aggregation:**

```typescript
// lib/server/routers/_app.ts
export const appRouter = router({
  products: productsRouter,
  orders: ordersRouter,
  users: usersRouter,
  admin: adminRouter,
})

export type AppRouter = typeof appRouter
```

---

### Validation Strategy

**Three-Layer Validation:**

1. **TypeScript** (compile-time) - Type correctness
2. **Zod** (runtime) - Request payload validation
3. **Database** (constraints) - Final enforcement

```typescript
// 1. Database schema
export const products = pgTable('products', {
  price: real('price').notNull(),  // DB constraint
})

// 2. Zod validation
export const insertProductParams = createSelectSchema(products, {
  price: z.number().positive(),  // Runtime validation
})

// 3. TypeScript types
export type NewProduct = z.infer<typeof insertProductParams>  // Compile-time
```

**Custom Validators:**

```typescript
// Reusable validators
export const validators = {
  uuid: z.string().uuid(),
  email: z.string().email().toLowerCase(),
  url: z.string().url(),
  phone: z.string().regex(/^\+?[1-9]\d{1,14}$/),
  slug: z.string().regex(/^[a-z0-9-]+$/),
  futureDate: z.date().min(new Date()),
}
```

---

### Error Handling

**Standardized Error Classes:**

```typescript
// lib/errors/AppError.ts
export class AppError extends Error {
  constructor(
    public code: string,
    message: string,
    public statusCode: number = 500,
    public details?: unknown,
  ) {
    super(message)
    this.name = 'AppError'
  }
}

export const errors = {
  notFound: (resource: string) =>
    new AppError('NOT_FOUND', `${resource} not found`, 404),

  unauthorized: () =>
    new AppError('UNAUTHORIZED', 'Unauthorized', 401),

  forbidden: (reason?: string) =>
    new AppError('FORBIDDEN', reason ?? 'Forbidden', 403),

  validation: (message: string, details?: unknown) =>
    new AppError('VALIDATION_ERROR', message, 400, details),

  conflict: (message: string) =>
    new AppError('CONFLICT', message, 409),
}
```

**Error Formatting (tRPC example):**

```typescript
export const createTRPCContext = async (opts: CreateNextContextOptions) => {
  return {
    userId: opts.auth.userId,
  }
}

export const t = initTRPC.context<typeof createTRPCContext>().create({
  errorFormatter({ shape, error }) {
    return {
      ...shape,
      data: {
        ...shape.data,
        zodError: error.cause instanceof ZodError
          ? error.cause.flatten()
          : null,
      },
    }
  },
})
```

**Client-side Handling:**

```typescript
const mutation = trpc.products.create.useMutation({
  onError: (error) => {
    if (error.data?.zodError) {
      // Field-level validation errors
      toast.error('Please check the form for errors')
    } else if (error.message) {
      // Application errors
      toast.error(error.message)
    } else {
      // Unknown errors
      toast.error('An unexpected error occurred')
    }
  },
})
```

---

## Authentication & Authorization

### Authentication Provider Options

**Three Main Approaches:**

#### Option 1: SaaS Provider (Clerk, Auth0, WorkOS)

**When to use:**
- ✅ Fast time to market
- ✅ Don't want to manage auth infrastructure
- ✅ Need advanced features (MFA, social logins, etc.)
- ✅ Small to medium user base

**Recommended: Clerk**

**Pros:**
- ✅ Excellent Next.js integration
- ✅ Beautiful prebuilt UI components
- ✅ Handles all security concerns
- ✅ MFA, social logins, magic links included
- ✅ Organizations/teams support
- ✅ Free tier (10,000 MAU)

**Cons:**
- ❌ Vendor lock-in
- ❌ Costs scale with users ($25/month per 1000 MAU)
- ❌ Less control over auth flow
- ❌ Data stored with third party

**Implementation:**

```typescript
// middleware.ts
import { authMiddleware } from '@clerk/nextjs'

export default authMiddleware({
  publicRoutes: ['/'],
})

// app/layout.tsx
import { ClerkProvider } from '@clerk/nextjs'

export default function RootLayout({ children }) {
  return (
    <ClerkProvider>
      <html>
        <body>{children}</body>
      </html>
    </ClerkProvider>
  )
}

// Get user in Server Component
import { currentUser } from '@clerk/nextjs'

const user = await currentUser()

// Get user in API
import { getAuth } from '@clerk/nextjs/server'

const { userId } = getAuth(req)
```

**HISCOXNDS Example:** Uses Clerk 4.29.3 successfully with test accounts and protected routes.

#### Option 2: NextAuth.js (Open Source)

**When to use:**
- ✅ Want full control
- ✅ Multiple auth providers (Google, GitHub, etc.)
- ✅ No vendor lock-in
- ✅ Cost-sensitive (self-hosted)

**Pros:**
- ✅ Free and open source
- ✅ Many provider integrations
- ✅ Active community
- ✅ Flexible adapters (Prisma, Drizzle, etc.)

**Cons:**
- ❌ More setup required
- ❌ You manage security
- ❌ Basic UI (need to build your own)
- ❌ Manual MFA implementation

**Implementation:**

```typescript
// app/api/auth/[...nextauth]/route.ts
import NextAuth from 'next-auth'
import { DrizzleAdapter } from '@auth/drizzle-adapter'
import GoogleProvider from 'next-auth/providers/google'

export const { handlers, auth } = NextAuth({
  adapter: DrizzleAdapter(db),
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    }),
  ],
})

export const { GET, POST } = handlers
```

#### Option 3: Custom Implementation

**When to use:**
- ✅ Unique requirements
- ✅ Want complete control
- ✅ Legacy system integration
- ❌ Generally NOT recommended

**Warning:** Authentication is hard to get right. Consider SaaS/OSS solutions first.

**If you must build custom:**

```typescript
// Use well-tested libraries
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'

// Password hashing
const hashedPassword = await bcrypt.hash(password, 12)

// JWT generation
const token = jwt.sign(
  { userId, email },
  process.env.JWT_SECRET,
  { expiresIn: '7d' }
)

// Validation
const payload = jwt.verify(token, process.env.JWT_SECRET)
```

**Must implement:**
- ✅ Password hashing (bcrypt/argon2)
- ✅ CSRF protection
- ✅ Session management
- ✅ Rate limiting
- ✅ Email verification
- ✅ Password reset
- ✅ Account lockout
- ✅ Security headers

---

### Authorization Patterns

#### Pattern 1: User ID-Based (Simplest)

```typescript
// Every record tracks owner
export const products = pgTable('products', {
  id: uuid('id').primaryKey(),
  userId: varchar('user_id').notNull(),
})

// Query only user's records
const userProducts = await db
  .select()
  .from(products)
  .where(eq(products.userId, currentUserId))
```

#### Pattern 2: Role-Based Access Control (RBAC)

```typescript
export const userRoles = pgEnum('user_role', ['admin', 'manager', 'user'])

export const users = pgTable('users', {
  role: userRoles('role').notNull().default('user'),
})

// Middleware
const requireAdmin = middleware(({ ctx, next }) => {
  if (ctx.user.role !== 'admin') {
    throw errors.forbidden('Admin access required')
  }
  return next({ ctx })
})

export const adminProcedure = protectedProcedure.use(requireAdmin)
```

#### Pattern 3: Permission-Based (Most Flexible)

```typescript
export const permissions = pgTable('permissions', {
  id: uuid('id').primaryKey(),
  resource: varchar('resource').notNull(),  // 'products'
  action: varchar('action').notNull(),      // 'create', 'read', etc.
})

export const rolePermissions = pgTable('role_permissions', {
  roleId: uuid('role_id').notNull(),
  permissionId: uuid('permission_id').notNull(),
})

// Check permission
const hasPermission = async (
  userId: string,
  resource: string,
  action: string
) => {
  const result = await db
    .select()
    .from(users)
    .innerJoin(rolePermissions, eq(users.roleId, rolePermissions.roleId))
    .innerJoin(permissions, eq(rolePermissions.permissionId, permissions.id))
    .where(
      and(
        eq(users.id, userId),
        eq(permissions.resource, resource),
        eq(permissions.action, action)
      )
    )

  return result.length > 0
}
```

#### Pattern 4: Row-Level Security (Postgres)

```sql
-- Enable RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own products
CREATE POLICY user_products ON products
  FOR SELECT
  USING (user_id = current_setting('app.user_id')::uuid);

-- Set user context per request
SET LOCAL app.user_id = '123e4567-e89b-12d3-a456-426614174000';
```

**Pros:**
- ✅ Database enforces security
- ✅ Cannot bypass in application code
- ✅ Works across all query types

**Cons:**
- ❌ Database-specific
- ❌ Can impact performance
- ❌ Harder to debug

---

## State Management

### Client-Side State Options

**Three-Layer Architecture Recommended:**

```
┌─────────────────────────────────────┐
│  Server State (React Query/tRPC)   │ ← Database data
├─────────────────────────────────────┤
│  Global Client State (Jotai/Zustand)│ ← UI state shared across components
├─────────────────────────────────────┤
│  Local State (useState/useReducer)  │ ← Component-only state
└─────────────────────────────────────┘
```

#### Layer 1: Server State (React Query)

**Purpose:** Manage data from APIs (caching, refetching, optimistic updates)

**Recommended:** React Query (built into tRPC)

```typescript
// With tRPC (includes React Query)
const { data, isLoading, error } = trpc.products.list.useQuery()

const createMutation = trpc.products.create.useMutation({
  onSuccess: () => {
    // Invalidate cache to refetch
    queryClient.invalidateQueries(['products'])
  },
})

// Optimistic update
const updateMutation = trpc.products.update.useMutation({
  onMutate: async (newProduct) => {
    // Cancel outgoing refetches
    await queryClient.cancelQueries(['products'])

    // Snapshot previous value
    const previous = queryClient.getQueryData(['products'])

    // Optimistically update
    queryClient.setQueryData(['products'], (old) => ({
      ...old,
      ...newProduct,
    }))

    return { previous }
  },
  onError: (err, variables, context) => {
    // Rollback on error
    queryClient.setQueryData(['products'], context?.previous)
  },
})
```

**Configuration:**

```typescript
// lib/trpc/provider.tsx
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 60 * 1000,        // 1 minute
      cacheTime: 5 * 60 * 1000,    // 5 minutes
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
})
```

**HISCOXNDS Example:** Uses TanStack Query 4.32.1 via tRPC for all server state.

#### Layer 2: Global Client State

**Purpose:** Share UI state across components (modals, filters, selections)

**Option A: Jotai (Atomic, Bottom-Up)**

**Pros:**
- ✅ Minimal boilerplate
- ✅ Automatic re-render optimization
- ✅ TypeScript-first
- ✅ Great for small to medium state

**Example:**

```typescript
// lib/atoms/ui.ts
import { atom } from 'jotai'

export const sidebarOpenAtom = atom(false)
export const selectedProductAtom = atom<string | null>(null)

// Component
import { useAtom } from 'jotai'

function Sidebar() {
  const [isOpen, setIsOpen] = useAtom(sidebarOpenAtom)

  return (
    <aside className={isOpen ? 'open' : 'closed'}>
      <button onClick={() => setIsOpen(false)}>Close</button>
    </aside>
  )
}
```

**HISCOXNDS Example:** Uses Jotai 2.6.1 for global UI state.

**Option B: Zustand (Store-Based, Top-Down)**

**Pros:**
- ✅ Simple API
- ✅ No providers needed
- ✅ Great DevTools
- ✅ Good for medium to large state

**Example:**

```typescript
// lib/store/ui.ts
import { create } from 'zustand'

interface UIStore {
  sidebarOpen: boolean
  selectedProduct: string | null
  toggleSidebar: () => void
  selectProduct: (id: string) => void
}

export const useUIStore = create<UIStore>((set) => ({
  sidebarOpen: false,
  selectedProduct: null,
  toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen })),
  selectProduct: (id) => set({ selectedProduct: id }),
}))

// Component
function Sidebar() {
  const { sidebarOpen, toggleSidebar } = useUIStore()

  return (
    <aside className={sidebarOpen ? 'open' : 'closed'}>
      <button onClick={toggleSidebar}>Close</button>
    </aside>
  )
}
```

**Option C: Context + useReducer (Built-in)**

**Pros:**
- ✅ No dependencies
- ✅ Built into React
- ✅ Familiar pattern

**Cons:**
- ❌ More boilerplate
- ❌ Performance concerns (re-render optimization manual)

**When to use:** Simple apps, avoid dependencies

#### Layer 3: Local State (useState)

**Purpose:** Component-only state (forms, toggles, etc.)

```typescript
function ProductForm() {
  const [name, setName] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)

  // Local state that doesn't need sharing
}
```

**Decision Matrix:**

| State Type | Tool | Example |
|------------|------|---------|
| Server data | React Query/tRPC | Products list, user profile |
| Global UI state | Jotai/Zustand | Theme, sidebar open, selected filters |
| Local UI state | useState | Form inputs, accordion open, hover state |

---

## Testing Strategy

### Testing Pyramid

```
        ╱ ╲
       ╱ E2E╲       ← Few tests, slow, expensive
      ╱─────╲
     ╱ Inte- ╲      ← Moderate tests, medium speed
    ╱gration ╲
   ╱──────────╲
  ╱   Unit     ╲    ← Many tests, fast, cheap
 ╱──────────────╲
```

**Recommended Distribution:**
- 70% Unit tests
- 20% Integration tests
- 10% E2E tests

### Unit Testing

**Tool:** Vitest (Recommended for Vite/Next.js)

**Why Vitest:**
- ✅ Fast (native ESM, parallelized)
- ✅ Compatible with Jest
- ✅ Great DX (watch mode, UI)
- ✅ Works well with TypeScript

**Setup:**

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./tests/setup.ts'],
  },
  resolve: {
    alias: {
      '@': '/src',
    },
  },
})
```

**Example Tests:**

```typescript
// tests/unit/lib/utils.test.ts
import { describe, it, expect } from 'vitest'
import { cn, formatCurrency } from '@/lib/utils'

describe('utils', () => {
  describe('cn', () => {
    it('merges class names', () => {
      expect(cn('foo', 'bar')).toBe('foo bar')
    })

    it('handles conditional classes', () => {
      expect(cn('foo', false && 'bar')).toBe('foo')
    })
  })

  describe('formatCurrency', () => {
    it('formats USD correctly', () => {
      expect(formatCurrency(1234.56)).toBe('$1,234.56')
    })
  })
})
```

### Integration Testing

**Purpose:** Test API routes, database interactions

```typescript
// tests/integration/api/products.test.ts
import { describe, it, expect, beforeEach } from 'vitest'
import { appRouter } from '@/lib/server/routers/_app'
import { db } from '@/lib/db'

describe('products router', () => {
  beforeEach(async () => {
    // Clean database
    await db.delete(products)
  })

  it('creates product', async () => {
    const caller = appRouter.createCaller({
      userId: 'test-user',
    })

    const result = await caller.products.create({
      name: 'Test Product',
      price: 99.99,
    })

    expect(result.product.id).toBeDefined()
    expect(result.product.name).toBe('Test Product')
  })

  it('lists user products only', async () => {
    // Create products for different users
    await db.insert(products).values([
      { userId: 'user-1', name: 'Product 1' },
      { userId: 'user-2', name: 'Product 2' },
    ])

    const caller = appRouter.createCaller({ userId: 'user-1' })
    const result = await caller.products.list()

    expect(result).toHaveLength(1)
    expect(result[0].name).toBe('Product 1')
  })
})
```

### E2E Testing

**Tool:** Playwright (Recommended)

**Why Playwright:**
- ✅ Fast and reliable
- ✅ Multi-browser (Chromium, Firefox, WebKit)
- ✅ Great debugging tools
- ✅ Auto-wait (no flaky tests)

**Setup:**

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
})
```

**Example:**

```typescript
// tests/e2e/products.spec.ts
import { test, expect } from '@playwright/test'

test('user can create product', async ({ page }) => {
  // Navigate to products page
  await page.goto('/products')

  // Click new product button
  await page.click('button:has-text("New Product")')

  // Fill form
  await page.fill('input[name="name"]', 'Test Product')
  await page.fill('input[name="price"]', '99.99')

  // Submit
  await page.click('button:has-text("Create")')

  // Verify product appears in list
  await expect(page.locator('text=Test Product')).toBeVisible()
})
```

### Test Data Management

**Factories Pattern:**

```typescript
// tests/factories/product.ts
import { faker } from '@faker-js/faker'

export const createProduct = (overrides = {}) => ({
  id: faker.string.uuid(),
  name: faker.commerce.productName(),
  price: parseFloat(faker.commerce.price()),
  createdAt: new Date(),
  ...overrides,
})

// Usage in tests
const product = createProduct({ name: 'Specific Name' })
```

**Database Seeding:**

```typescript
// tests/helpers/seed.ts
export const seedDatabase = async () => {
  await db.insert(products).values([
    createProduct({ name: 'Product 1' }),
    createProduct({ name: 'Product 2' }),
  ])
}
```

---

## Security Architecture

### Security Checklist

**Essential Security Measures:**

- ✅ Authentication on all non-public routes
- ✅ Input validation (Zod) on all API endpoints
- ✅ SQL injection prevention (ORM)
- ✅ XSS prevention (React auto-escaping)
- ✅ CSRF protection (SameSite cookies)
- ✅ Rate limiting on APIs
- ✅ Security headers (CSP, HSTS, etc.)
- ✅ HTTPS in production
- ✅ Secrets in environment variables (not code)
- ✅ Audit logging

### Security Headers

```typescript
// next.config.mjs
export default {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block',
          },
          {
            key: 'Permissions-Policy',
            value: 'camera=(), microphone=(), geolocation=()',
          },
          {
            key: 'Strict-Transport-Security',
            value: 'max-age=31536000; includeSubDomains',
          },
          {
            key: 'Content-Security-Policy',
            value: [
              "default-src 'self'",
              "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
              "style-src 'self' 'unsafe-inline'",
              "img-src 'self' data: https:",
              "font-src 'self'",
              "connect-src 'self' https:",
            ].join('; '),
          },
        ],
      },
    ]
  },
}
```

### Rate Limiting

**Option 1: Upstash Rate Limiting**

```typescript
// lib/middleware/rateLimit.ts
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '10s'),
})

export const checkRateLimit = async (identifier: string) => {
  const { success, limit, remaining } = await ratelimit.limit(identifier)

  if (!success) {
    throw new Error('Rate limit exceeded')
  }

  return { limit, remaining }
}

// Usage in API
const { success } = await ratelimit.limit(req.ip)
if (!success) {
  return new Response('Too Many Requests', { status: 429 })
}
```

**Option 2: In-Memory (Simple)**

```typescript
import { LRUCache } from 'lru-cache'

const ratelimit = new LRUCache<string, number>({
  max: 500,
  ttl: 60000, // 1 minute
})

export const checkRateLimit = (ip: string, limit = 10) => {
  const current = ratelimit.get(ip) ?? 0

  if (current >= limit) {
    throw new Error('Rate limit exceeded')
  }

  ratelimit.set(ip, current + 1)
}
```

### Input Sanitization

```typescript
// lib/validation/sanitize.ts
export const sanitizeString = (input: string): string => {
  return input
    .trim()
    .replace(/[<>]/g, '')              // Remove HTML tags
    .replace(/javascript:/gi, '')      // Remove JS protocols
    .replace(/on\w+=/gi, '')           // Remove event handlers
    .slice(0, 1000)                    // Max length
}

// Zod transformer
export const sanitizedString = z.string().transform(sanitizeString)

// Usage
export const insertProductParams = z.object({
  name: sanitizedString,
  description: sanitizedString,
})
```

---

## Deployment Architecture

### Deployment Options

#### Option 1: Vercel (Easiest)

**Pros:**
- ✅ Zero-config deployment
- ✅ Global CDN
- ✅ Automatic HTTPS
- ✅ Preview deployments
- ✅ Built for Next.js

**Cons:**
- ❌ Vendor lock-in
- ❌ Serverless limitations
- ❌ Cost at scale

**Setup:**
```bash
pnpm install -g vercel
vercel
```

#### Option 2: Docker + Cloud (Flexible)

**Pros:**
- ✅ Full control
- ✅ Any cloud provider
- ✅ Cost-effective at scale
- ✅ Portable

**Cons:**
- ❌ More setup
- ❌ Manual scaling
- ❌ Infrastructure management

**Dockerfile:**

```dockerfile
# Multi-stage build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && pnpm install --frozen-lockfile
COPY . .
RUN pnpm build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/next.config.mjs ./
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

EXPOSE 3000
CMD ["pnpm", "start"]
```

**docker-compose.yml:**

```yaml
version: '3.8'

services:
  ui:
    build: ./ui
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: ${DATABASE_URL}
      CLERK_SECRET_KEY: ${CLERK_SECRET_KEY}
    depends_on:
      - db

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

#### Option 3: Kubernetes (Enterprise)

**When to use:**
- ✅ Large scale (>100 instances)
- ✅ Multi-region
- ✅ Complex deployments
- ✅ Need auto-scaling

**Cons:**
- ❌ Complex setup
- ❌ Steep learning curve
- ❌ Overkill for small apps

**Helm Chart Example:**

```yaml
# values.yaml
replicaCount: 3

image:
  repository: your-registry/app
  tag: latest

service:
  type: LoadBalancer
  port: 80

ingress:
  enabled: true
  hosts:
    - host: app.example.com
      paths:
        - path: /
  tls:
    - secretName: app-tls
      hosts:
        - app.example.com
```

**HISCOXNDS Example:** Docker Compose with nginx reverse proxy. Works for single-server deployment.

---

## Optional Services

### Background Jobs

**When Needed:**
- Long-running operations (>30 seconds)
- Scheduled tasks
- Retry-able operations
- Email sending

**Recommended:** BullMQ

```typescript
// lib/jobs/queue.ts
import { Queue, Worker } from 'bullmq'
import Redis from 'ioredis'

const connection = new Redis({
  host: process.env.REDIS_HOST,
  port: 6379,
})

export const emailQueue = new Queue('email', { connection })

// Add job
await emailQueue.add('welcome-email', {
  userId: '123',
  email: 'user@example.com',
})

// Worker
const worker = new Worker(
  'email',
  async (job) => {
    await sendEmail(job.data)
  },
  { connection }
)
```

### Caching Layer

**When Needed:**
- Expensive queries
- External API calls
- High read/write ratio

**Recommended:** Redis (Upstash for serverless)

```typescript
// lib/cache/redis.ts
import { Redis } from '@upstash/redis'

const redis = Redis.fromEnv()

export const cache = {
  get: async <T>(key: string): Promise<T | null> => {
    return await redis.get(key)
  },

  set: async <T>(key: string, value: T, ttl = 3600) => {
    await redis.setex(key, ttl, value)
  },

  invalidate: async (pattern: string) => {
    const keys = await redis.keys(pattern)
    if (keys.length > 0) {
      await redis.del(...keys)
    }
  },
}

// Usage
const products = await cache.get('products:all')
if (!products) {
  const fresh = await db.select().from(productsTable)
  await cache.set('products:all', fresh, 300) // 5 min
  return fresh
}
return products
```

### External Computation Service

**When Needed:**
- Different language required (R, Python)
- Heavy computation isolated from web app
- Specific libraries not available in Node.js

**Pattern:**

```
Next.js App  ──HTTP──>  External Service (R/Python/Go)
                              │
                              ▼
                         Specialized
                         Computation
```

**Example (R with Plumber):**

```r
# plumber.R
#* Calculate statistics
#* @param data Numeric vector
#* @post /calculate
function(data) {
  list(
    mean = mean(data),
    sd = sd(data),
    quantiles = quantile(data)
  )
}
```

**Next.js Integration:**

```typescript
const response = await fetch('http://compute-service:7071/calculate', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ data: [1, 2, 3, 4, 5] }),
})

const results = await response.json()
```

**HISCOXNDS Example:** R Plumber service for graph-based reinsurance calculations. Handles complex actuarial algorithms.

---

## Reference Implementation

**HISCOXNDS serves as a working example** of these patterns:

- ✅ Schema-driven development (Drizzle + Zod)
- ✅ tRPC for type-safe API
- ✅ Comprehensive audit logging
- ✅ Clerk authentication
- ✅ Docker Compose orchestration
- ✅ External service pattern (R)
- ✅ Consistent CRUD patterns

**What HISCOXNDS lacks (improvements for new projects):**
- ❌ Automated testing
- ❌ Error boundaries
- ❌ Rate limiting
- ❌ Structured logging
- ❌ Production security headers

**Use HISCOXNDS as reference for:**
- Database schema patterns
- tRPC router organization
- Component structure
- Audit logging implementation
- Docker setup

---

## Summary: Decision Framework

When starting a new enterprise Next.js project:

### Must Haves
1. **TypeScript** - Non-negotiable
2. **Next.js** (latest) with App Router
3. **PostgreSQL** (local + cloud option)
4. **Authentication** (Clerk recommended for speed, NextAuth for control)
5. **Validation** (Zod schemas)
6. **Testing** (Vitest + Playwright)

### Choose Based on Context
- **API Style**: tRPC (internal) vs REST (public API)
- **ORM**: Drizzle (new projects) vs Prisma (mature ecosystem)
- **State**: Jotai (atomic) vs Zustand (store-based)
- **Deployment**: Vercel (easy) vs Docker (control)

### Add When Needed
- Background jobs (BullMQ)
- Caching (Redis/Upstash)
- External services (R/Python)
- Monitoring (Sentry)
- Analytics

---

**Next Steps:**
- Review [PROJECT_SETUP_GUIDE.md](#) for step-by-step implementation
- Review [BEST_PRACTICES.md](#) for coding patterns
- Reference HISCOXNDS codebase for working examples

**Questions or Feedback:**
This is a living document. Submit issues or improvements via pull request.

---

**Version History:**
- v1.0 (2026-01-25) - Initial release based on HISCOXNDS learnings
