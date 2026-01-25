# Enterprise Next.js Project Setup Guide

**Version:** 1.0
**Last Updated:** 2026-01-25
**Companion Document:** TEMPLATE_ARCHITECTURE.md

---

## Purpose

This guide provides a step-by-step playbook for setting up a new enterprise-grade Next.js application from scratch. Follow these steps to create a production-ready foundation with best practices built in from day one.

**Time Estimate:** 2-4 hours for basic setup, 1-2 days with all optional features

**Reference:** The HISCOXNDS project demonstrates all these patterns in a working application.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Project Setup](#initial-project-setup)
3. [Database Setup](#database-setup)
4. [Authentication Implementation](#authentication-implementation)
5. [API Layer Setup](#api-layer-setup)
6. [UI Foundation](#ui-foundation)
7. [Testing Infrastructure](#testing-infrastructure)
8. [Security Hardening](#security-hardening)
9. [Development Workflow](#development-workflow)
10. [Deployment Preparation](#deployment-preparation)
11. [Post-Setup Checklist](#post-setup-checklist)

---

## Prerequisites

### Required Tools

```bash
# Node.js 20+ (LTS)
node --version  # Should be v20.x.x or higher

# pnpm (recommended package manager)
corepack enable
pnpm --version

# Docker (for local database)
docker --version
docker-compose --version

# Git
git --version
```

### Accounts to Create

- [ ] **GitHub/GitLab** - Code repository
- [ ] **Clerk.com** OR **Auth0** - Authentication (if using SaaS)
- [ ] **Neon.tech** OR **Supabase** - Cloud database (optional)
- [ ] **Vercel** OR **Railway** - Deployment (optional)
- [ ] **Sentry.io** - Error monitoring (optional)

---

## Initial Project Setup

### Step 1: Create Next.js Project

```bash
# Create project with latest Next.js
pnpm create next-app@latest my-enterprise-app

# Options to select:
✔ Would you like to use TypeScript? Yes
✔ Would you like to use ESLint? Yes
✔ Would you like to use Tailwind CSS? Yes
✔ Would you like to use `src/` directory? No (use app/ router)
✔ Would you like to use App Router? Yes (recommended)
✔ Would you like to customize the default import alias? Yes (@/*)

cd my-enterprise-app
```

### Step 2: Configure TypeScript Strict Mode

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "allowJs": true,
    "forceConsistentCasingInFileNames": true,
    "incremental": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

### Step 3: Install Core Dependencies

```bash
# API Layer (choose one)
# Option A: tRPC (recommended for TypeScript monoliths)
pnpm add @trpc/server @trpc/client @trpc/next @trpc/react-query @tanstack/react-query superjson

# Database & ORM
# Option A: Drizzle (recommended)
pnpm add drizzle-orm postgres
pnpm add -D drizzle-kit

# Option B: Prisma (alternative)
# pnpm add @prisma/client && pnpm add -D prisma

# Validation
pnpm add zod drizzle-zod

# Authentication (choose one)
# Option A: Clerk (recommended for speed)
pnpm add @clerk/nextjs

# Option B: NextAuth (open source alternative)
# pnpm add next-auth @auth/drizzle-adapter

# UI Components
pnpm add class-variance-authority clsx tailwind-merge
pnpm add lucide-react

# Forms
pnpm add react-hook-form @hookform/resolvers

# Date handling
pnpm add date-fns

# Development
pnpm add -D @types/node typescript eslint prettier
```

### Step 4: Configure ESLint & Prettier

```json
// .eslintrc.json
{
  "extends": [
    "next/core-web-vitals",
    "prettier"
  ],
  "rules": {
    "@typescript-eslint/no-unused-vars": [
      "error",
      {
        "argsIgnorePattern": "^_",
        "varsIgnorePattern": "^_"
      }
    ],
    "@typescript-eslint/consistent-type-imports": [
      "warn",
      {
        "prefer": "type-imports",
        "fixStyle": "inline-type-imports"
      }
    ]
  }
}
```

```json
// .prettierrc
{
  "semi": false,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100,
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

```bash
# Install Prettier
pnpm add -D prettier prettier-plugin-tailwindcss eslint-config-prettier
```

### Step 5: Setup Git and Environment

```bash
# Initialize git (if not done)
git init
git add .
git commit -m "Initial commit"

# Create .env.local for secrets
touch .env.local

# Add to .gitignore
echo ".env.local" >> .gitignore
echo ".env*.local" >> .gitignore

# Create .env.example (template)
cat > .env.example << 'EOF'
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
LOCAL_DB=TRUE

# Authentication (Clerk)
CLERK_SECRET_KEY=sk_test_...
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_...

# Optional: Error Monitoring
SENTRY_DSN=

# Optional: Analytics
NEXT_PUBLIC_ANALYTICS_ID=
EOF
```

---

## Database Setup

### Option A: Local PostgreSQL with Docker

**Step 1: Create docker-compose.yml**

```yaml
# docker-compose.yml
version: '3.8'

services:
  db:
    image: postgres:15-alpine
    container_name: ${PROJECT_NAME:-myapp}_db
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-myapp_db}
      POSTGRES_USER: ${POSTGRES_USER:-myapp_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-changeme}
    ports:
      - '5432:5432'
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U ${POSTGRES_USER:-myapp_user}']
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

**Step 2: Start Database**

```bash
# Start PostgreSQL
docker-compose up -d db

# Verify it's running
docker-compose ps

# Check logs
docker-compose logs db
```

**Step 3: Configure Database Connection**

```bash
# .env.local
LOCAL_DB=TRUE
LOCAL_DATABASE_URL=postgresql://myapp_user:changeme@localhost:5432/myapp_db
```

### Option B: Cloud Database (Neon/Supabase)

**For Neon:**

```bash
# 1. Sign up at neon.tech
# 2. Create new project
# 3. Copy connection string

# .env.local
LOCAL_DB=FALSE
DATABASE_URL=postgresql://user:pass@ep-xxx.us-east-2.aws.neon.tech/dbname?sslmode=require
```

**For Supabase:**

```bash
# 1. Sign up at supabase.com
# 2. Create new project
# 3. Go to Settings → Database
# 4. Copy connection string (Session mode for Prisma, Transaction mode for Drizzle)

# .env.local
DATABASE_URL=postgresql://postgres:[password]@db.[project].supabase.co:5432/postgres
```

### Step 6: Setup Drizzle ORM

**Create database connection:**

```typescript
// lib/db/index.ts
import { drizzle } from 'drizzle-orm/postgres-js'
import postgres from 'postgres'

const LOCAL_DB = process.env.LOCAL_DB === 'TRUE'

// Connection strings
const localDatabaseURL = process.env.LOCAL_DATABASE_URL!
const cloudDatabaseURL = process.env.DATABASE_URL!

// Create connection
const connectionString = LOCAL_DB ? localDatabaseURL : cloudDatabaseURL
const client = postgres(connectionString, {
  max: 10,
  idle_timeout: 20,
  connect_timeout: 10,
})

export const db = drizzle(client)
```

**Configure Drizzle Kit:**

```typescript
// drizzle.config.ts
import type { Config } from 'drizzle-kit'

export default {
  schema: './lib/db/schema/*.ts',
  out: './lib/db/migrations',
  driver: 'pg',
  dbCredentials: {
    connectionString:
      process.env.LOCAL_DB === 'TRUE'
        ? process.env.LOCAL_DATABASE_URL!
        : process.env.DATABASE_URL!,
  },
} satisfies Config
```

### Step 7: Create Database Schema

**Create schema directory:**

```bash
mkdir -p lib/db/schema
```

**Define base enums:**

```typescript
// lib/db/schema/enums.ts
import { pgEnum } from 'drizzle-orm/pg-core'

export const recordActionEnum = pgEnum('record_action_enum', [
  'CREATED',
  'UPDATED',
  'DELETED',
])

export const recordApprovalEnum = pgEnum('record_approval_enum', [
  'DRAFT',
  'SUBMITTED',
  'APPROVED',
  'REJECTED',
])
```

**Create users table:**

```typescript
// lib/db/schema/users.ts
import { pgTable, uuid, varchar, timestamp } from 'drizzle-orm/pg-core'
import { createInsertSchema, createSelectSchema } from 'drizzle-zod'
import { z } from 'zod'

export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: varchar('email', { length: 256 }).notNull().unique(),
  firstName: varchar('first_name', { length: 256 }),
  lastName: varchar('last_name', { length: 256 }),
  imageUrl: varchar('image_url', { length: 512 }),

  // Auth provider ID (Clerk, Auth0, etc.)
  authUserId: varchar('auth_user_id', { length: 64 }).notNull().unique(),

  // Timestamps
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
})

// Zod schemas
export const insertUserSchema = createInsertSchema(users)
export const selectUserSchema = createSelectSchema(users)

// Refined schemas
export const insertUserParams = insertUserSchema.extend({
  email: z.string().email().toLowerCase(),
  firstName: z.string().min(1).max(256).optional(),
  lastName: z.string().min(1).max(256).optional(),
})

// TypeScript types
export type User = typeof users.$inferSelect
export type NewUser = z.infer<typeof insertUserParams>
```

**Create example domain table:**

```typescript
// lib/db/schema/products.ts
import { pgTable, uuid, varchar, text, real, timestamp } from 'drizzle-orm/pg-core'
import { createInsertSchema, createSelectSchema } from 'drizzle-zod'
import { z } from 'zod'
import { users } from './users'
import { recordActionEnum, recordApprovalEnum } from './enums'

export const products = pgTable('products', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: varchar('name', { length: 256 }).notNull(),
  description: text('description'),
  price: real('price').notNull(),
  category: varchar('category', { length: 100 }),

  // Ownership
  userId: uuid('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),

  // Audit fields
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),
  createdBy: varchar('created_by', { length: 64 }).notNull(),
  operationType: recordActionEnum('operation_type').notNull().default('CREATED'),
  approvalStatus: recordApprovalEnum('approval_status').notNull().default('DRAFT'),
  approvedBy: varchar('approved_by', { length: 64 }),
  approvedAt: timestamp('approved_at'),
})

// Zod schemas
export const insertProductSchema = createInsertSchema(products)
export const selectProductSchema = createSelectSchema(products)

export const insertProductParams = insertProductSchema.extend({
  name: z.string().min(1, 'Name is required').max(256),
  description: z.string().max(5000).optional(),
  price: z.number().positive('Price must be positive'),
  category: z.string().max(100).optional(),
})

export const updateProductParams = insertProductParams.partial().extend({
  id: z.string().uuid(),
})

// Types
export type Product = typeof products.$inferSelect
export type NewProduct = z.infer<typeof insertProductParams>
export type UpdateProduct = z.infer<typeof updateProductParams>
```

**Create audit logs table:**

```typescript
// lib/db/schema/auditLogs.ts
import { pgTable, serial, varchar, uuid, timestamp, jsonb } from 'drizzle-orm/pg-core'

export const auditLogs = pgTable('audit_logs', {
  id: serial('id').primaryKey(),
  tableName: varchar('table_name', { length: 256 }).notNull(),
  recordId: uuid('record_id').notNull(),
  operation: varchar('operation', { length: 32 }).notNull(), // INSERT, UPDATE, DELETE
  changedAt: timestamp('changed_at').notNull().defaultNow(),
  changedBy: varchar('changed_by', { length: 64 }).notNull(),

  // Store complete before/after state
  originalValues: jsonb('original_values'),
  newValues: jsonb('new_values').notNull(),
})
```

### Step 8: Generate and Run Migrations

```bash
# Generate migration from schema
pnpm drizzle-kit generate

# This creates: lib/db/migrations/0000_initial.sql

# Review the SQL file
cat lib/db/migrations/0000_*.sql

# Apply migration
pnpm drizzle-kit push

# Or create migration runner script
```

**Migration runner script:**

```typescript
// lib/db/migrate.ts
import { drizzle } from 'drizzle-orm/postgres-js'
import { migrate } from 'drizzle-orm/postgres-js/migrator'
import postgres from 'postgres'

const runMigration = async () => {
  const connectionString =
    process.env.LOCAL_DB === 'TRUE'
      ? process.env.LOCAL_DATABASE_URL!
      : process.env.DATABASE_URL!

  const client = postgres(connectionString, { max: 1 })
  const db = drizzle(client)

  console.log('⏳ Running migrations...')

  await migrate(db, { migrationsFolder: 'lib/db/migrations' })

  console.log('✅ Migrations complete!')

  await client.end()
}

runMigration().catch((err) => {
  console.error('❌ Migration failed!')
  console.error(err)
  process.exit(1)
})
```

**Add to package.json:**

```json
{
  "scripts": {
    "db:generate": "drizzle-kit generate",
    "db:migrate": "tsx lib/db/migrate.ts",
    "db:push": "drizzle-kit push",
    "db:studio": "drizzle-kit studio"
  }
}
```

### Step 9: Create Seed Data

```typescript
// lib/db/seed.ts
import { db } from './index'
import { users, products } from './schema'
import { faker } from '@faker-js/faker'

const seed = async () => {
  console.log('⏳ Seeding database...')

  // Create test users
  const [admin] = await db
    .insert(users)
    .values([
      {
        email: 'admin@example.com',
        firstName: 'Admin',
        lastName: 'User',
        authUserId: 'user_admin',
      },
    ])
    .returning()

  console.log('✅ Created users')

  // Create sample products
  await db.insert(products).values(
    Array.from({ length: 10 }, () => ({
      name: faker.commerce.productName(),
      description: faker.commerce.productDescription(),
      price: parseFloat(faker.commerce.price()),
      category: faker.commerce.department(),
      userId: admin.id,
      createdBy: admin.authUserId,
    }))
  )

  console.log('✅ Created products')
  console.log('🎉 Seeding complete!')
}

seed()
  .catch((error) => {
    console.error('❌ Seed failed!')
    console.error(error)
    process.exit(1)
  })
  .finally(() => process.exit(0))
```

**Add to package.json:**

```json
{
  "scripts": {
    "db:seed": "tsx lib/db/seed.ts"
  },
  "devDependencies": {
    "@faker-js/faker": "^8.3.1",
    "tsx": "^4.7.0"
  }
}
```

**Run seed:**

```bash
pnpm add -D @faker-js/faker tsx
pnpm db:seed
```

---

## Authentication Implementation

### Option A: Clerk (Fastest Setup)

**Step 1: Install Clerk**

```bash
pnpm add @clerk/nextjs
```

**Step 2: Get Clerk Keys**

1. Sign up at https://clerk.com
2. Create new application
3. Copy API keys from dashboard

```bash
# .env.local
CLERK_SECRET_KEY=sk_test_xxxxxxxxxxxxx
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxx
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/
```

**Step 3: Setup Middleware**

```typescript
// middleware.ts
import { authMiddleware } from '@clerk/nextjs'

export default authMiddleware({
  publicRoutes: ['/'],
})

export const config = {
  matcher: ['/((?!.+\\.[\\w]+$|_next).*)', '/', '/(api|trpc)(.*)'],
}
```

**Step 4: Add Provider**

```typescript
// app/layout.tsx
import { ClerkProvider } from '@clerk/nextjs'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body>{children}</body>
      </html>
    </ClerkProvider>
  )
}
```

**Step 5: Create Auth Pages**

```typescript
// app/(auth)/sign-in/[[...sign-in]]/page.tsx
import { SignIn } from '@clerk/nextjs'

export default function Page() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <SignIn />
    </div>
  )
}
```

```typescript
// app/(auth)/sign-up/[[...sign-up]]/page.tsx
import { SignUp } from '@clerk/nextjs'

export default function Page() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <SignUp />
    </div>
  )
}
```

**Step 6: Use in Components**

```typescript
// Server Component
import { currentUser } from '@clerk/nextjs'

export default async function Page() {
  const user = await currentUser()

  if (!user) return <div>Not signed in</div>

  return <div>Hello {user.firstName}!</div>
}

// Client Component
'use client'

import { useUser } from '@clerk/nextjs'

export function UserProfile() {
  const { user } = useUser()

  return <div>{user?.emailAddresses[0].emailAddress}</div>
}
```

### Option B: NextAuth.js (Open Source)

**Step 1: Install NextAuth**

```bash
pnpm add next-auth @auth/drizzle-adapter
```

**Step 2: Configure NextAuth**

```typescript
// lib/auth.ts
import NextAuth from 'next-auth'
import { DrizzleAdapter } from '@auth/drizzle-adapter'
import GoogleProvider from 'next-auth/providers/google'
import { db } from './db'

export const { handlers, auth, signIn, signOut } = NextAuth({
  adapter: DrizzleAdapter(db),
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
  ],
  callbacks: {
    session({ session, user }) {
      session.user.id = user.id
      return session
    },
  },
})
```

**Step 3: Create API Route**

```typescript
// app/api/auth/[...nextauth]/route.ts
import { handlers } from '@/lib/auth'

export const { GET, POST } = handlers
```

**Step 4: Create Auth Tables**

NextAuth requires specific tables. Generate schema from docs or use Drizzle adapter.

---

## API Layer Setup

### Option A: tRPC (Recommended)

**Step 1: Create tRPC Router**

```typescript
// lib/server/trpc.ts
import { initTRPC, TRPCError } from '@trpc/server'
import { type CreateNextContextOptions } from '@trpc/server/adapters/next'
import { getAuth } from '@clerk/nextjs/server'
import superjson from 'superjson'
import { ZodError } from 'zod'

// Create context from request
export const createTRPCContext = async (opts: CreateNextContextOptions) => {
  const { userId } = getAuth(opts.req)

  return {
    userId,
    req: opts.req,
    res: opts.res,
  }
}

// Initialize tRPC
const t = initTRPC.context<typeof createTRPCContext>().create({
  transformer: superjson,
  errorFormatter({ shape, error }) {
    return {
      ...shape,
      data: {
        ...shape.data,
        zodError: error.cause instanceof ZodError ? error.cause.flatten() : null,
      },
    }
  },
})

// Middleware for authentication
const isAuthed = t.middleware(({ ctx, next }) => {
  if (!ctx.userId) {
    throw new TRPCError({ code: 'UNAUTHORIZED' })
  }
  return next({
    ctx: {
      userId: ctx.userId,
    },
  })
})

// Export reusable router and procedure helpers
export const router = t.router
export const publicProcedure = t.procedure
export const protectedProcedure = t.procedure.use(isAuthed)
```

**Step 2: Create Data Access Layer**

```typescript
// lib/api/products/queries.ts
import { db } from '@/lib/db'
import { products } from '@/lib/db/schema'
import { eq } from 'drizzle-orm'

export const getProducts = async (userId: string) => {
  return await db.select().from(products).where(eq(products.userId, userId))
}

export const getProductById = async (id: string, userId: string) => {
  const result = await db
    .select()
    .from(products)
    .where(eq(products.id, id))
    .where(eq(products.userId, userId))
    .limit(1)

  return result[0] ?? null
}
```

```typescript
// lib/api/products/mutations.ts
import { db } from '@/lib/db'
import { products, type NewProduct } from '@/lib/db/schema'
import { eq } from 'drizzle-orm'

export const createProduct = async (data: NewProduct) => {
  const [product] = await db.insert(products).values(data).returning()
  return product
}

export const updateProduct = async (id: string, data: Partial<NewProduct>) => {
  const [updated] = await db
    .update(products)
    .set({ ...data, updatedAt: new Date() })
    .where(eq(products.id, id))
    .returning()

  return updated
}

export const deleteProduct = async (id: string) => {
  await db.delete(products).where(eq(products.id, id))
}
```

**Step 3: Create Router**

```typescript
// lib/server/routers/products.ts
import { z } from 'zod'
import { router, protectedProcedure } from '../trpc'
import { insertProductParams, updateProductParams } from '@/lib/db/schema/products'
import * as queries from '@/lib/api/products/queries'
import * as mutations from '@/lib/api/products/mutations'

export const productsRouter = router({
  list: protectedProcedure.query(async ({ ctx }) => {
    return await queries.getProducts(ctx.userId)
  }),

  getById: protectedProcedure
    .input(z.object({ id: z.string().uuid() }))
    .query(async ({ input, ctx }) => {
      return await queries.getProductById(input.id, ctx.userId)
    }),

  create: protectedProcedure
    .input(insertProductParams)
    .mutation(async ({ input, ctx }) => {
      return await mutations.createProduct({
        ...input,
        userId: ctx.userId,
        createdBy: ctx.userId,
      })
    }),

  update: protectedProcedure
    .input(updateProductParams)
    .mutation(async ({ input }) => {
      const { id, ...data } = input
      return await mutations.updateProduct(id, data)
    }),

  delete: protectedProcedure
    .input(z.object({ id: z.string().uuid() }))
    .mutation(async ({ input }) => {
      await mutations.deleteProduct(input.id)
      return { success: true }
    }),
})
```

**Step 4: Create App Router**

```typescript
// lib/server/routers/_app.ts
import { router } from '../trpc'
import { productsRouter } from './products'

export const appRouter = router({
  products: productsRouter,
})

export type AppRouter = typeof appRouter
```

**Step 5: Create API Route**

```typescript
// app/api/trpc/[trpc]/route.ts
import { fetchRequestHandler } from '@trpc/server/adapters/fetch'
import { type NextRequest } from 'next/server'
import { appRouter } from '@/lib/server/routers/_app'
import { createTRPCContext } from '@/lib/server/trpc'

const handler = (req: NextRequest) =>
  fetchRequestHandler({
    endpoint: '/api/trpc',
    req,
    router: appRouter,
    createContext: createTRPCContext,
  })

export { handler as GET, handler as POST }
```

**Step 6: Setup Client**

```typescript
// lib/trpc/client.ts
import { createTRPCReact } from '@trpc/react-query'
import { type AppRouter } from '@/lib/server/routers/_app'

export const trpc = createTRPCReact<AppRouter>()
```

```typescript
// lib/trpc/provider.tsx
'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { httpBatchLink } from '@trpc/client'
import { useState } from 'react'
import { trpc } from './client'
import superjson from 'superjson'

export function TRPCProvider({ children }: { children: React.Node }) {
  const [queryClient] = useState(() => new QueryClient())

  const [trpcClient] = useState(() =>
    trpc.createClient({
      transformer: superjson,
      links: [
        httpBatchLink({
          url: '/api/trpc',
        }),
      ],
    })
  )

  return (
    <trpc.Provider client={trpcClient} queryClient={queryClient}>
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    </trpc.Provider>
  )
}
```

**Step 7: Add Provider to Layout**

```typescript
// app/layout.tsx
import { TRPCProvider } from '@/lib/trpc/provider'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider>
      <html lang="en">
        <body>
          <TRPCProvider>{children}</TRPCProvider>
        </body>
      </html>
    </ClerkProvider>
  )
}
```

**Step 8: Use in Components**

```typescript
// app/products/page.tsx
'use client'

import { trpc } from '@/lib/trpc/client'

export default function ProductsPage() {
  const { data: products, isLoading } = trpc.products.list.useQuery()

  const createMutation = trpc.products.create.useMutation({
    onSuccess: () => {
      // Invalidate cache
      queryClient.invalidateQueries(['products'])
    },
  })

  if (isLoading) return <div>Loading...</div>

  return (
    <div>
      <h1>Products</h1>
      {products?.map((product) => (
        <div key={product.id}>{product.name}</div>
      ))}
    </div>
  )
}
```

---

## UI Foundation

### Step 1: Install shadcn/ui

```bash
pnpm dlx shadcn-ui@latest init

# Options:
✔ Which style would you like to use? › Default
✔ Which color would you like to use as base color? › Slate
✔ Do you want to use CSS variables for colors? › yes
```

### Step 2: Add Essential Components

```bash
# Core components
pnpm dlx shadcn-ui@latest add button
pnpm dlx shadcn-ui@latest add form
pnpm dlx shadcn-ui@latest add input
pnpm dlx shadcn-ui@latest add label
pnpm dlx shadcn-ui@latest add table
pnpm dlx shadcn-ui@latest add dialog
pnpm dlx shadcn-ui@latest add dropdown-menu
pnpm dlx shadcn-ui@latest add card
pnpm dlx shadcn-ui@latest add toast

# Data display
pnpm dlx shadcn-ui@latest add badge
pnpm dlx shadcn-ui@latest add avatar
pnpm dlx shadcn-ui@latest add separator

# Navigation
pnpm dlx shadcn-ui@latest add navigation-menu
pnpm dlx shadcn-ui@latest add sheet
```

### Step 3: Create Layout Components

```typescript
// components/site/header.tsx
import { UserButton } from '@clerk/nextjs'
import { ModeToggle } from './mode-toggle'

export function Header() {
  return (
    <header className="border-b">
      <div className="container flex h-16 items-center justify-between">
        <div className="flex gap-6">
          <h1 className="text-2xl font-bold">MyApp</h1>
          {/* Navigation */}
        </div>
        <div className="flex items-center gap-4">
          <ModeToggle />
          <UserButton afterSignOutUrl="/" />
        </div>
      </div>
    </header>
  )
}
```

```typescript
// components/site/sidebar.tsx
import Link from 'next/link'
import { Home, Package, Settings } from 'lucide-react'

const navigation = [
  { name: 'Dashboard', href: '/', icon: Home },
  { name: 'Products', href: '/products', icon: Package },
  { name: 'Settings', href: '/settings', icon: Settings },
]

export function Sidebar() {
  return (
    <aside className="w-64 border-r bg-gray-50 dark:bg-gray-900">
      <nav className="space-y-1 p-4">
        {navigation.map((item) => (
          <Link
            key={item.name}
            href={item.href}
            className="flex items-center gap-3 rounded-lg px-3 py-2 hover:bg-gray-100 dark:hover:bg-gray-800"
          >
            <item.icon className="h-5 w-5" />
            <span>{item.name}</span>
          </Link>
        ))}
      </nav>
    </aside>
  )
}
```

### Step 4: Create Dashboard Layout

```typescript
// app/(dashboard)/layout.tsx
import { Header } from '@/components/site/header'
import { Sidebar } from '@/components/site/sidebar'

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex h-screen flex-col">
      <Header />
      <div className="flex flex-1 overflow-hidden">
        <Sidebar />
        <main className="flex-1 overflow-y-auto p-8">{children}</main>
      </div>
    </div>
  )
}
```

---

## Testing Infrastructure

### Step 1: Install Testing Libraries

```bash
# Unit & Integration Testing
pnpm add -D vitest @vitest/ui @vitejs/plugin-react jsdom
pnpm add -D @testing-library/react @testing-library/jest-dom @testing-library/user-event

# E2E Testing
pnpm add -D @playwright/test
pnpx playwright install chromium
```

### Step 2: Configure Vitest

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./tests/setup.ts'],
    include: ['tests/**/*.test.{ts,tsx}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './'),
    },
  },
})
```

**Setup file:**

```typescript
// tests/setup.ts
import '@testing-library/jest-dom'
import { expect, afterEach } from 'vitest'
import { cleanup } from '@testing-library/react'

afterEach(() => {
  cleanup()
})
```

### Step 3: Configure Playwright

```bash
# Initialize Playwright
pnpx playwright install
```

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  webServer: {
    command: 'pnpm dev',
    port: 3000,
    reuseExistingServer: !process.env.CI,
  },
})
```

### Step 4: Write Example Tests

```typescript
// tests/unit/lib/utils.test.ts
import { describe, it, expect } from 'vitest'
import { cn } from '@/lib/utils'

describe('cn utility', () => {
  it('merges class names', () => {
    expect(cn('foo', 'bar')).toBe('foo bar')
  })
})
```

```typescript
// tests/e2e/auth.spec.ts
import { test, expect } from '@playwright/test'

test('user can sign in', async ({ page }) => {
  await page.goto('/sign-in')
  await page.fill('input[name="identifier"]', 'test@example.com')
  await page.fill('input[name="password"]', 'password')
  await page.click('button[type="submit"]')

  await expect(page).toHaveURL('/')
})
```

### Step 5: Add Test Scripts

```json
// package.json
{
  "scripts": {
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui"
  }
}
```

---

## Security Hardening

### Step 1: Add Security Headers

```typescript
// next.config.mjs
const nextConfig = {
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          { key: 'X-Frame-Options', value: 'DENY' },
          { key: 'X-Content-Type-Options', value: 'nosniff' },
          { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
          { key: 'X-XSS-Protection', value: '1; mode=block' },
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
            ].join('; '),
          },
        ],
      },
    ]
  },
}

export default nextConfig
```

### Step 2: Add Error Boundaries

```typescript
// app/error.tsx
'use client'

import { useEffect } from 'react'
import { Button } from '@/components/ui/button'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    console.error(error)
  }, [error])

  return (
    <div className="flex h-screen flex-col items-center justify-center">
      <h2 className="text-xl font-bold">Something went wrong!</h2>
      <p className="text-gray-600">{error.message}</p>
      <Button onClick={reset} className="mt-4">
        Try again
      </Button>
    </div>
  )
}
```

### Step 3: Add Rate Limiting (Optional)

```bash
pnpm add @upstash/ratelimit @upstash/redis
```

```typescript
// lib/rate-limit.ts
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

export const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '10 s'),
})
```

---

## Development Workflow

### Step 1: Setup Scripts

```json
// package.json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "type-check": "tsc --noEmit",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "db:generate": "drizzle-kit generate",
    "db:migrate": "tsx lib/db/migrate.ts",
    "db:push": "drizzle-kit push",
    "db:seed": "tsx lib/db/seed.ts",
    "db:studio": "drizzle-kit studio",
    "test": "vitest",
    "test:e2e": "playwright test",
    "validate": "pnpm type-check && pnpm lint && pnpm test"
  }
}
```

### Step 2: Setup Git Hooks (Optional)

```bash
pnpm add -D husky lint-staged

# Initialize husky
pnpx husky init
```

```bash
# .husky/pre-commit
pnpm lint-staged
```

```json
// package.json
{
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md}": ["prettier --write"]
  }
}
```

### Step 3: Daily Development Flow

```bash
# Start development server
pnpm dev

# In another terminal, open Drizzle Studio to inspect DB
pnpm db:studio

# Make schema changes
# Edit lib/db/schema/*.ts

# Generate migration
pnpm db:generate

# Apply migration
pnpm db:migrate

# Run tests
pnpm test

# Before committing
pnpm validate
```

---

## Deployment Preparation

### Step 1: Build for Production

```bash
# Test production build locally
pnpm build
pnpm start
```

### Step 2: Environment Variables

Create production environment variables in your deployment platform:

```
# Required
DATABASE_URL=postgresql://...
CLERK_SECRET_KEY=sk_live_...
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_live_...

# Optional
SENTRY_DSN=https://...
```

### Step 3: Deploy to Vercel

```bash
# Install Vercel CLI
pnpm add -g vercel

# Deploy
vercel

# Deploy to production
vercel --prod
```

### Step 4: Deploy with Docker

```dockerfile
# Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app
RUN corepack enable

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

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

```bash
# Build and run
docker build -t my-app .
docker run -p 3000:3000 --env-file .env.local my-app
```

---

## Post-Setup Checklist

### Essential Items

- [ ] TypeScript strict mode enabled
- [ ] Database connected and migrated
- [ ] Authentication working (can sign in/out)
- [ ] First API endpoint working
- [ ] Basic UI components rendering
- [ ] Environment variables documented in .env.example
- [ ] .gitignore includes .env.local

### Security

- [ ] Security headers configured
- [ ] All routes protected except public ones
- [ ] Input validation on all API endpoints
- [ ] Error boundaries in place
- [ ] HTTPS in production

### Testing

- [ ] Vitest configured
- [ ] Playwright configured
- [ ] Example unit test passing
- [ ] Example E2E test passing

### Documentation

- [ ] README.md updated with project-specific info
- [ ] .env.example complete
- [ ] API documented (or self-documenting with tRPC)

### Optional

- [ ] CI/CD pipeline set up
- [ ] Error monitoring (Sentry)
- [ ] Analytics
- [ ] Logging
- [ ] Rate limiting

---

## Next Steps

1. **Build Your Domain Models**
   - Create additional database tables
   - Write schema validation
   - Add relationships

2. **Implement Features**
   - Create API routers for each domain
   - Build UI components
   - Write tests

3. **Polish**
   - Add loading states
   - Improve error messages
   - Add success notifications (toast)

4. **Monitor & Iterate**
   - Set up error tracking
   - Monitor performance
   - Gather user feedback

---

**Resources:**
- Next.js Docs: https://nextjs.org/docs
- tRPC Docs: https://trpc.io/docs
- Drizzle Docs: https://orm.drizzle.team/docs
- Clerk Docs: https://clerk.com/docs
- shadcn/ui: https://ui.shadcn.com

**Reference Implementation:** Review the HISCOXNDS project for working examples of all these patterns.

---

**Version History:**
- v1.0 (2026-01-25) - Initial release
