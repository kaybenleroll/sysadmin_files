# Enterprise Next.js Best Practices

**Version:** 1.0
**Last Updated:** 2026-01-25
**Reference Implementation:** HISCOXNDS

---

## Purpose

This document catalogues proven patterns, coding standards, and best practices for building maintainable enterprise Next.js applications. Examples are drawn from production systems (particularly HISCOXNDS) and industry standards.

**Use this guide for:**
- Code review standards
- Onboarding new developers
- Architectural decision-making
- Identifying anti-patterns

---

## Table of Contents

1. [Code Organization](#code-organization)
2. [Database Patterns](#database-patterns)
3. [API Patterns](#api-patterns)
4. [Component Patterns](#component-patterns)
5. [State Management](#state-management)
6. [Error Handling](#error-handling)
7. [Testing Patterns](#testing-patterns)
8. [Security Best Practices](#security-best-practices)
9. [Performance Optimization](#performance-optimization)
10. [Common Anti-Patterns to Avoid](#common-anti-patterns-to-avoid)

---

## Code Organization

### Pattern: Domain-Driven Structure

**✅ DO: Organize by domain/feature**

```
lib/
├── api/
│   ├── products/
│   │   ├── queries.ts      # All product reads
│   │   └── mutations.ts    # All product writes
│   ├── orders/
│   │   ├── queries.ts
│   │   └── mutations.ts
│   └── users/
│       ├── queries.ts
│       └── mutations.ts
```

**❌ DON'T: Organize by technical layer**

```
lib/
├── controllers/
├── services/
├── repositories/
└── models/
```

**Why:** Domain organization makes it easier to find related code and understand feature scope.

### Pattern: Colocation

**✅ DO: Keep related files together**

```
features/products/
├── schema.ts              # Database schema
├── validation.ts          # Zod schemas
├── api/
│   ├── queries.ts
│   └── mutations.ts
├── components/
│   ├── ProductList.tsx
│   ├── ProductForm.tsx
│   └── ProductCard.tsx
└── __tests__/
    └── products.test.ts
```

**Why:** Reduces context switching and makes refactoring easier.

### Pattern: Clear Naming Conventions

**✅ DO: Use descriptive, consistent names**

```typescript
// Files
ProductForm.tsx              // Component (PascalCase)
queries.ts                   // Utilities (camelCase)
product-card.module.css      // Styles (kebab-case)

// Functions
getUserById()                // Verb + noun
validateProductInput()       // Verb + noun
isAuthenticated()            // Boolean prefix (is/has/can)

// Constants
MAX_FILE_SIZE               // UPPER_SNAKE_CASE
DEFAULT_PAGE_SIZE           // UPPER_SNAKE_CASE

// Types
type Product = {...}        // Noun (PascalCase)
type CreateProductInput     // Action + noun
interface UserRepository    // Noun + type
```

### Pattern: Barrel Exports (Use Sparingly)

**✅ DO: Export from index when grouping related utilities**

```typescript
// lib/utils/index.ts
export { cn } from './cn'
export { formatDate } from './date'
export { formatCurrency } from './currency'
```

**❌ DON'T: Over-use barrel exports (hurts tree-shaking)**

```typescript
// ❌ Exporting everything from schema
export * from './schema/products'
export * from './schema/orders'
// ... 30 more exports
```

**Why:** Barrel exports can prevent tree-shaking and create circular dependencies.

**HISCOXNDS Example:** Does NOT use barrel exports. Imports are explicit: `import { products } from '@/lib/db/schema/products'`

---

## Database Patterns

### Pattern: Schema-First Development

**✅ DO: Start with database schema, derive everything else**

```typescript
// 1. Define Drizzle schema (source of truth)
export const products = pgTable('products', {
  id: uuid('id').primaryKey().defaultRandom(),
  name: varchar('name', { length: 256 }).notNull(),
  price: real('price').notNull(),
})

// 2. Generate Zod schemas
export const insertProductSchema = createInsertSchema(products)

// 3. Refine validation
export const insertProductParams = insertProductSchema.extend({
  name: z.string().min(1).max(256),
  price: z.number().positive(),
})

// 4. Derive TypeScript types
export type Product = typeof products.$inferSelect
export type NewProduct = z.infer<typeof insertProductParams>
```

**Why:**
- Single source of truth
- Types update automatically
- Compile-time errors guide refactoring
- Runtime validation matches database constraints

**HISCOXNDS Example:** All 30 tables follow this pattern consistently.

### Pattern: Comprehensive Audit Logging

**✅ DO: Track all changes with standard fields**

```typescript
export const baseAuditFields = {
  // Timestamps
  createdAt: timestamp('created_at').notNull().defaultNow(),
  updatedAt: timestamp('updated_at').notNull().defaultNow(),

  // Ownership
  createdBy: varchar('created_by', { length: 64 }).notNull(),
  updatedBy: varchar('updated_by', { length: 64 }),

  // Workflow
  operationType: recordActionEnum('operation_type').notNull(),
  approvalStatus: recordApprovalEnum('approval_status').notNull(),
  approvedBy: varchar('approved_by', { length: 64 }),
  approvedAt: timestamp('approved_at'),
}

// Apply to all tables
export const products = pgTable('products', {
  id: uuid('id').primaryKey(),
  name: varchar('name').notNull(),
  ...baseAuditFields,
})
```

**Why:**
- Compliance requirements (SOX, GDPR, HIPAA)
- Debugging (who changed what and when)
- Audit trails for business logic
- Workflow tracking

**HISCOXNDS Example:** Every table includes temporal/audit fields. Separate `audit_logs` table captures complete before/after state in JSONB.

### Pattern: Separate Audit Logs Table

**✅ DO: Keep complete change history**

```typescript
export const auditLogs = pgTable('audit_logs', {
  id: serial('id').primaryKey(),
  tableName: varchar('table_name').notNull(),
  recordId: uuid('record_id').notNull(),
  operation: varchar('operation').notNull(), // INSERT, UPDATE, DELETE
  changedAt: timestamp('changed_at').notNull().defaultNow(),
  changedBy: varchar('changed_by').notNull(),

  // Complete before/after state
  originalValues: jsonb('original_values'),
  newValues: jsonb('new_values').notNull(),
})
```

**Trigger implementation:**

```sql
CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_logs (
    table_name, record_id, operation, changed_by,
    original_values, new_values
  )
  VALUES (
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    TG_OP,
    COALESCE(NEW.updated_by, NEW.created_by),
    row_to_json(OLD),
    row_to_json(NEW)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables
CREATE TRIGGER products_audit
  AFTER INSERT OR UPDATE OR DELETE ON products
  FOR EACH ROW EXECUTE FUNCTION audit_trigger();
```

### Pattern: Smart Indexing

**✅ DO: Index based on query patterns**

```sql
-- Foreign keys (for joins)
CREATE INDEX idx_products_user_id ON products(user_id);

-- Filter columns (for WHERE clauses)
CREATE INDEX idx_products_status ON products(status);
CREATE INDEX idx_products_category ON products(category);

-- Sort columns (for ORDER BY)
CREATE INDEX idx_products_created_at ON products(created_at DESC);

-- Composite indexes (for combined filters)
CREATE INDEX idx_products_user_status
  ON products(user_id, status);

-- Partial indexes (for frequent filters)
CREATE INDEX idx_active_products
  ON products(category)
  WHERE status = 'active';
```

**❌ DON'T: Index everything**

```sql
-- ❌ Unnecessary indexes
CREATE INDEX idx_products_description ON products(description);  -- Text field
CREATE INDEX idx_products_id ON products(id);  -- Already primary key
```

**Why:** Indexes speed up reads but slow down writes. Index based on actual query patterns.

### Pattern: Enums for Fixed Values

**✅ DO: Use database enums for status fields**

```typescript
export const productStatus = pgEnum('product_status', [
  'draft',
  'published',
  'archived',
])

export const products = pgTable('products', {
  status: productStatus('status').notNull().default('draft'),
})
```

**Why:**
- Type-safe in TypeScript
- Database enforces valid values
- Self-documenting
- Easy to query

**❌ DON'T: Use magic strings**

```typescript
// ❌ No type safety
status: varchar('status')  // Can be any string!
```

**HISCOXNDS Example:** Uses `recordActionEnum` and `recordApprovalEnum` consistently across all tables.

### Pattern: Soft Deletes for Important Data

**✅ DO: Use soft deletes for user data**

```typescript
export const products = pgTable('products', {
  id: uuid('id').primaryKey(),
  deletedAt: timestamp('deleted_at'),  // NULL = active
})

// Query only active records
const activeProducts = await db
  .select()
  .from(products)
  .where(isNull(products.deletedAt))

// Soft delete
await db
  .update(products)
  .set({ deletedAt: new Date() })
  .where(eq(products.id, productId))
```

**When to use:**
- User-generated content
- Financial records
- Compliance requirements

**When NOT to use:**
- Session data
- Temporary/cache data
- Log data (use TTL instead)

---

## API Patterns

### Pattern: Consistent CRUD Operations

**✅ DO: Follow standard CRUD pattern**

```typescript
// lib/server/routers/products.ts
export const productsRouter = router({
  // List (with filters)
  list: protectedProcedure
    .input(z.object({
      category: z.string().optional(),
      limit: z.number().min(1).max(100).default(50),
      offset: z.number().min(0).default(0),
    }))
    .query(async ({ input, ctx }) => {
      return await queries.getProducts(ctx.userId, input)
    }),

  // Get by ID
  getById: protectedProcedure
    .input(z.object({ id: z.string().uuid() }))
    .query(async ({ input, ctx }) => {
      return await queries.getProductById(input.id, ctx.userId)
    }),

  // Create
  create: protectedProcedure
    .input(insertProductParams)
    .mutation(async ({ input, ctx }) => {
      return await mutations.createProduct(input, ctx.userId)
    }),

  // Update
  update: protectedProcedure
    .input(updateProductParams)
    .mutation(async ({ input, ctx }) => {
      return await mutations.updateProduct(input)
    }),

  // Delete
  delete: protectedProcedure
    .input(z.object({ id: z.string().uuid() }))
    .mutation(async ({ input, ctx }) => {
      return await mutations.deleteProduct(input.id, ctx.userId)
    }),
})
```

**Why:** Consistency makes code predictable and easier to maintain.

**HISCOXNDS Example:** All 30+ routers follow this exact pattern.

### Pattern: Separation of Queries and Mutations

**✅ DO: Split reads from writes**

```typescript
// lib/api/products/queries.ts
export const getProducts = async (userId: string, filters: ProductFilters) => {
  let query = db
    .select()
    .from(products)
    .where(eq(products.userId, userId))

  if (filters.category) {
    query = query.where(eq(products.category, filters.category))
  }

  return await query.limit(filters.limit).offset(filters.offset)
}

// lib/api/products/mutations.ts
export const createProduct = async (data: NewProduct, userId: string) => {
  const [product] = await db
    .insert(products)
    .values({
      ...data,
      userId,
      createdBy: userId,
      createdAt: new Date(),
    })
    .returning()

  return product
}
```

**Why:**
- Clear separation of concerns
- Easy to add caching to queries
- Easier to test
- Can optimize reads and writes differently

**HISCOXNDS Example:** Every domain has separate `queries.ts` and `mutations.ts` files.

### Pattern: Input Validation

**✅ DO: Validate all inputs with Zod**

```typescript
// Define schema
export const insertProductParams = z.object({
  name: z.string().min(1, 'Name is required').max(256),
  description: z.string().max(5000).optional(),
  price: z.number().positive('Price must be positive'),
  category: z.enum(['electronics', 'clothing', 'books']),
})

// Use in endpoint
create: protectedProcedure
  .input(insertProductParams)  // Automatic validation
  .mutation(async ({ input }) => {
    // Input is guaranteed to be valid
    return await createProduct(input)
  })
```

**❌ DON'T: Skip validation**

```typescript
// ❌ No validation
create: protectedProcedure
  .mutation(async ({ input }) => {
    // input could be anything!
    return await createProduct(input)
  })
```

### Pattern: Consistent Error Handling

**✅ DO: Use standard error classes**

```typescript
// lib/errors/AppError.ts
export class AppError extends Error {
  constructor(
    public code: string,
    message: string,
    public statusCode: number = 500,
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

  forbidden: () =>
    new AppError('FORBIDDEN', 'Forbidden', 403),

  validation: (message: string) =>
    new AppError('VALIDATION_ERROR', message, 400),
}

// Usage in API
const product = await getProductById(id, userId)
if (!product) {
  throw errors.notFound('Product')
}
```

**Why:**
- Consistent error responses
- Easy to handle in client
- Proper HTTP status codes
- Type-safe error codes

### Pattern: Authorization at API Level

**✅ DO: Check permissions in API layer**

```typescript
getById: protectedProcedure
  .input(z.object({ id: z.string().uuid() }))
  .query(async ({ input, ctx }) => {
    const product = await queries.getProductById(input.id)

    if (!product) {
      throw errors.notFound('Product')
    }

    // Check ownership
    if (product.userId !== ctx.userId) {
      throw errors.forbidden()
    }

    return product
  })
```

**❌ DON'T: Rely only on client-side checks**

```typescript
// ❌ Anyone can query any product
getById: protectedProcedure
  .input(z.object({ id: z.string().uuid() }))
  .query(async ({ input }) => {
    return await queries.getProductById(input.id)
    // No ownership check!
  })
```

---

## Component Patterns

### Pattern: Server Components by Default

**✅ DO: Use Server Components unless you need interactivity**

```typescript
// app/products/page.tsx (Server Component)
import { db } from '@/lib/db'
import { products } from '@/lib/db/schema'

export default async function ProductsPage() {
  // Fetch data directly in Server Component
  const allProducts = await db.select().from(products)

  return (
    <div>
      <h1>Products</h1>
      {allProducts.map((product) => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  )
}
```

**❌ DON'T: Use Client Components unnecessarily**

```typescript
// ❌ Unnecessary 'use client'
'use client'

export default function ProductsPage() {
  const { data } = trpc.products.list.useQuery()  // Could be Server Component
  // ...
}
```

**When to use Client Components:**
- Need state (`useState`, `useReducer`)
- Need effects (`useEffect`)
- Need event handlers (`onClick`, etc.)
- Need browser APIs

### Pattern: Component Composition

**✅ DO: Compose small, focused components**

```typescript
// ✅ Good: Small, reusable components
function ProductCard({ product }: { product: Product }) {
  return (
    <Card>
      <CardHeader>
        <ProductTitle name={product.name} />
        <ProductBadge status={product.status} />
      </CardHeader>
      <CardContent>
        <ProductDescription text={product.description} />
        <ProductPrice price={product.price} />
      </CardContent>
      <CardFooter>
        <ProductActions productId={product.id} />
      </CardFooter>
    </Card>
  )
}
```

**❌ DON'T: Create monolithic components**

```typescript
// ❌ Bad: 500-line component doing everything
function ProductPage() {
  // Tons of logic
  // Multiple responsibilities
  // Hard to test
  // Hard to reuse
}
```

### Pattern: Props Type Safety

**✅ DO: Define explicit prop types**

```typescript
interface ProductCardProps {
  product: Product
  onEdit?: (id: string) => void
  onDelete?: (id: string) => void
  showActions?: boolean
}

export function ProductCard({
  product,
  onEdit,
  onDelete,
  showActions = true,
}: ProductCardProps) {
  // ...
}
```

**❌ DON'T: Use implicit any**

```typescript
// ❌ No type safety
export function ProductCard({ product, onEdit, onDelete }) {
  // TypeScript doesn't know what these are
}
```

### Pattern: Consistent Form Handling

**✅ DO: Use React Hook Form + Zod**

```typescript
'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { insertProductParams, type NewProduct } from '@/lib/db/schema/products'

export function ProductForm() {
  const form = useForm<NewProduct>({
    resolver: zodResolver(insertProductParams),
    defaultValues: {
      name: '',
      price: 0,
    },
  })

  const createMutation = trpc.products.create.useMutation({
    onSuccess: () => {
      toast.success('Product created')
      form.reset()
    },
    onError: (error) => {
      toast.error(error.message)
    },
  })

  const onSubmit = (data: NewProduct) => {
    createMutation.mutate(data)
  }

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)}>
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Name</FormLabel>
              <FormControl>
                <Input {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <Button type="submit" disabled={createMutation.isLoading}>
          {createMutation.isLoading ? 'Creating...' : 'Create Product'}
        </Button>
      </form>
    </Form>
  )
}
```

**Why:**
- Type-safe form values
- Automatic validation
- Error handling
- Loading states

### Pattern: Loading and Error States

**✅ DO: Always handle loading and error states**

```typescript
'use client'

export function ProductList() {
  const { data, isLoading, error } = trpc.products.list.useQuery()

  if (isLoading) {
    return <ProductListSkeleton />
  }

  if (error) {
    return (
      <Alert variant="destructive">
        <AlertTitle>Error loading products</AlertTitle>
        <AlertDescription>{error.message}</AlertDescription>
      </Alert>
    )
  }

  if (!data || data.length === 0) {
    return (
      <div className="text-center text-gray-500">
        <p>No products found</p>
        <Button onClick={() => router.push('/products/new')}>
          Create your first product
        </Button>
      </div>
    )
  }

  return (
    <div>
      {data.map((product) => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  )
}
```

**❌ DON'T: Ignore loading/error states**

```typescript
// ❌ No loading or error handling
export function ProductList() {
  const { data } = trpc.products.list.useQuery()

  return (
    <div>
      {data.map((product) => (  // Crashes if data is undefined!
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  )
}
```

---

## State Management

### Pattern: Three-Layer State

**✅ DO: Use appropriate state management for each layer**

```typescript
// Layer 1: Server State (React Query via tRPC)
const { data: products } = trpc.products.list.useQuery()

// Layer 2: Global Client State (Jotai)
const [sidebarOpen, setSidebarOpen] = useAtom(sidebarOpenAtom)

// Layer 3: Local State (useState)
const [searchTerm, setSearchTerm] = useState('')
```

**Why:** Each layer has different caching, revalidation, and sharing requirements.

### Pattern: Optimistic Updates

**✅ DO: Use optimistic updates for better UX**

```typescript
const updateMutation = trpc.products.update.useMutation({
  onMutate: async (newProduct) => {
    // Cancel outgoing refetches
    await queryClient.cancelQueries(['products'])

    // Snapshot previous value
    const previous = queryClient.getQueryData(['products'])

    // Optimistically update
    queryClient.setQueryData(['products'], (old: Product[]) =>
      old.map((p) => (p.id === newProduct.id ? { ...p, ...newProduct } : p))
    )

    return { previous }
  },

  onError: (err, variables, context) => {
    // Rollback on error
    if (context?.previous) {
      queryClient.setQueryData(['products'], context.previous)
    }
    toast.error('Failed to update product')
  },

  onSettled: () => {
    // Refetch to ensure sync
    queryClient.invalidateQueries(['products'])
  },
})
```

### Pattern: Cache Invalidation

**✅ DO: Invalidate related queries after mutations**

```typescript
const createMutation = trpc.products.create.useMutation({
  onSuccess: () => {
    // Invalidate related queries
    queryClient.invalidateQueries(['products'])
    queryClient.invalidateQueries(['categories'])  // If products affect categories
    queryClient.invalidateQueries(['dashboard'])   // If shown on dashboard

    toast.success('Product created')
  },
})
```

---

## Error Handling

### Pattern: Error Boundaries

**✅ DO: Add error boundaries at strategic levels**

```typescript
// app/error.tsx (Root level)
'use client'

import { useEffect } from 'react'

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    // Log to error reporting service
    console.error(error)
  }, [error])

  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="text-center">
        <h2 className="text-2xl font-bold">Something went wrong!</h2>
        <p className="text-gray-600">{error.message}</p>
        <button onClick={reset}>Try again</button>
      </div>
    </div>
  )
}
```

**Add error boundaries at:**
- Root level (`app/error.tsx`)
- Route group level (`app/(dashboard)/error.tsx`)
- Feature level (reusable `<ErrorBoundary>` component)

### Pattern: Graceful Degradation

**✅ DO: Provide fallbacks**

```typescript
function ProductImage({ url, alt }: { url: string; alt: string }) {
  const [error, setError] = useState(false)

  if (error) {
    return (
      <div className="flex h-48 items-center justify-center bg-gray-200">
        <ImageIcon className="h-12 w-12 text-gray-400" />
      </div>
    )
  }

  return (
    <img
      src={url}
      alt={alt}
      onError={() => setError(true)}
      className="h-48 w-full object-cover"
    />
  )
}
```

### Pattern: User-Friendly Error Messages

**✅ DO: Show helpful messages**

```typescript
// ❌ Bad: Technical errors to users
toast.error('TypeError: Cannot read property "map" of undefined')

// ✅ Good: User-friendly messages
toast.error('Failed to load products. Please try again.')

// ✅ Even better: Actionable messages
toast.error('Failed to load products. Check your connection and try again.', {
  action: {
    label: 'Retry',
    onClick: () => refetch(),
  },
})
```

---

## Testing Patterns

### Pattern: Test Structure (AAA)

**✅ DO: Use Arrange-Act-Assert pattern**

```typescript
describe('createProduct', () => {
  it('creates product with valid data', async () => {
    // Arrange: Set up test data
    const testProduct = {
      name: 'Test Product',
      price: 99.99,
      userId: 'user-123',
    }

    // Act: Execute the function
    const result = await createProduct(testProduct)

    // Assert: Verify the outcome
    expect(result.id).toBeDefined()
    expect(result.name).toBe('Test Product')
    expect(result.price).toBe(99.99)
  })
})
```

### Pattern: Test Data Factories

**✅ DO: Use factories for test data**

```typescript
// tests/factories/product.ts
import { faker } from '@faker-js/faker'

export const createTestProduct = (overrides = {}) => ({
  id: faker.string.uuid(),
  name: faker.commerce.productName(),
  price: parseFloat(faker.commerce.price()),
  category: faker.commerce.department(),
  userId: faker.string.uuid(),
  createdAt: new Date(),
  ...overrides,
})

// Usage in tests
it('filters products by category', () => {
  const electronicsProduct = createTestProduct({ category: 'electronics' })
  const clothingProduct = createTestProduct({ category: 'clothing' })
  // ...
})
```

### Pattern: Mock External Dependencies

**✅ DO: Mock external services**

```typescript
import { vi } from 'vitest'

// Mock email service
vi.mock('@/lib/email', () => ({
  sendEmail: vi.fn().mockResolvedValue({ success: true }),
}))

it('sends welcome email on signup', async () => {
  await signupUser({ email: 'test@example.com' })

  expect(sendEmail).toHaveBeenCalledWith({
    to: 'test@example.com',
    template: 'welcome',
  })
})
```

### Pattern: E2E Test Critical Paths

**✅ DO: Test complete user workflows**

```typescript
import { test, expect } from '@playwright/test'

test('user can create and delete product', async ({ page }) => {
  // Login
  await page.goto('/sign-in')
  await page.fill('input[name="email"]', 'test@example.com')
  await page.fill('input[name="password"]', 'password')
  await page.click('button[type="submit"]')

  // Create product
  await page.goto('/products')
  await page.click('button:has-text("New Product")')
  await page.fill('input[name="name"]', 'Test Product')
  await page.fill('input[name="price"]', '99.99')
  await page.click('button:has-text("Create")')

  // Verify product appears
  await expect(page.locator('text=Test Product')).toBeVisible()

  // Delete product
  await page.click('[data-testid="product-menu"]')
  await page.click('button:has-text("Delete")')
  await page.click('button:has-text("Confirm")')

  // Verify product removed
  await expect(page.locator('text=Test Product')).not.toBeVisible()
})
```

---

## Security Best Practices

### Pattern: Input Sanitization

**✅ DO: Sanitize user input**

```typescript
import DOMPurify from 'isomorphic-dompurify'

// Remove HTML tags
export const sanitizeString = (input: string): string => {
  return input
    .trim()
    .replace(/[<>]/g, '')
    .replace(/javascript:/gi, '')
    .slice(0, 1000)  // Max length
}

// Use in Zod schema
export const sanitizedString = z.string()
  .transform(sanitizeString)

// For rich text, use DOMPurify
export const sanitizeHtml = (html: string): string => {
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['b', 'i', 'em', 'strong', 'a', 'p'],
    ALLOWED_ATTR: ['href'],
  })
}
```

### Pattern: Prevent SQL Injection

**✅ DO: Use ORM parameterized queries**

```typescript
// ✅ Safe: Drizzle uses parameterized queries
await db
  .select()
  .from(products)
  .where(eq(products.id, userInput))

// ✅ Safe: Even with raw SQL
await db.execute(
  sql`SELECT * FROM products WHERE id = ${userInput}`
)
```

**❌ DON'T: Concatenate SQL strings**

```typescript
// ❌ Vulnerable to SQL injection
await db.execute(`SELECT * FROM products WHERE id = '${userInput}'`)
```

### Pattern: Prevent XSS

**✅ DO: Let React escape by default**

```typescript
// ✅ React automatically escapes
<div>{userInput}</div>

// ✅ For rich text, sanitize first
<div dangerouslySetInnerHTML={{ __html: sanitizeHtml(userInput) }} />
```

**❌ DON'T: Use dangerouslySetInnerHTML without sanitization**

```typescript
// ❌ XSS vulnerable
<div dangerouslySetInnerHTML={{ __html: userInput }} />
```

### Pattern: Rate Limiting

**✅ DO: Implement rate limiting**

```typescript
import { Ratelimit } from '@upstash/ratelimit'
import { Redis } from '@upstash/redis'

const ratelimit = new Ratelimit({
  redis: Redis.fromEnv(),
  limiter: Ratelimit.slidingWindow(10, '10 s'),
})

// In API route
export async function POST(req: Request) {
  const ip = req.headers.get('x-forwarded-for') ?? 'unknown'
  const { success } = await ratelimit.limit(ip)

  if (!success) {
    return new Response('Too many requests', { status: 429 })
  }

  // Continue with request
}
```

### Pattern: Environment Variable Validation

**✅ DO: Validate environment variables at startup**

```typescript
// lib/env.ts
import { z } from 'zod'

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  CLERK_SECRET_KEY: z.string().min(1),
  NODE_ENV: z.enum(['development', 'production', 'test']),
})

export const env = envSchema.parse(process.env)

// Now env is type-safe
const dbUrl = env.DATABASE_URL  // TypeScript knows this is a string
```

---

## Performance Optimization

### Pattern: Lazy Loading

**✅ DO: Lazy load heavy components**

```typescript
import dynamic from 'next/dynamic'

// Lazy load chart library
const Chart = dynamic(() => import('@/components/Chart'), {
  loading: () => <ChartSkeleton />,
  ssr: false,  // Don't render on server if using browser APIs
})

export function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>
      <Chart data={data} />
    </div>
  )
}
```

### Pattern: Image Optimization

**✅ DO: Use Next.js Image component**

```typescript
import Image from 'next/image'

export function ProductImage({ src, alt }: { src: string; alt: string }) {
  return (
    <Image
      src={src}
      alt={alt}
      width={400}
      height={300}
      className="rounded-lg"
      placeholder="blur"
      blurDataURL="/placeholder.jpg"
    />
  )
}
```

### Pattern: Database Query Optimization

**✅ DO: Select only needed fields**

```typescript
// ✅ Good: Select specific fields
const products = await db
  .select({
    id: products.id,
    name: products.name,
    price: products.price,
  })
  .from(products)

// ❌ Bad: Select all fields
const products = await db.select().from(products)  // Returns everything
```

**✅ DO: Use pagination**

```typescript
const PAGE_SIZE = 50

const products = await db
  .select()
  .from(products)
  .limit(PAGE_SIZE)
  .offset(page * PAGE_SIZE)
```

---

## Common Anti-Patterns to Avoid

### Anti-Pattern: Prop Drilling

**❌ DON'T: Pass props through many levels**

```typescript
// ❌ Bad: Props drilled through multiple levels
<App>
  <Layout theme={theme}>
    <Sidebar theme={theme}>
      <Menu theme={theme}>
        <MenuItem theme={theme} />
      </Menu>
    </Sidebar>
  </Layout>
</App>
```

**✅ DO: Use Context or global state**

```typescript
// ✅ Good: Context for shared values
<ThemeProvider theme={theme}>
  <App>
    <Layout>
      <Sidebar>
        <Menu>
          <MenuItem />  {/* Gets theme from context */}
        </Menu>
      </Sidebar>
    </Layout>
  </App>
</ThemeProvider>
```

### Anti-Pattern: Stale Closures

**❌ DON'T: Reference stale values in effects**

```typescript
// ❌ Bad: Stale closure
function Counter() {
  const [count, setCount] = useState(0)

  useEffect(() => {
    const timer = setInterval(() => {
      setCount(count + 1)  // Always uses initial count!
    }, 1000)
    return () => clearInterval(timer)
  }, [])  // Missing dependency
}
```

**✅ DO: Use functional updates or include dependencies**

```typescript
// ✅ Good: Functional update
useEffect(() => {
  const timer = setInterval(() => {
    setCount((prev) => prev + 1)  // Uses current value
  }, 1000)
  return () => clearInterval(timer)
}, [])
```

### Anti-Pattern: Overusing useEffect

**❌ DON'T: Use useEffect for derived state**

```typescript
// ❌ Bad: Synchronizing state with useEffect
function ProductList({ products }: { products: Product[] }) {
  const [filteredProducts, setFilteredProducts] = useState<Product[]>([])

  useEffect(() => {
    setFilteredProducts(products.filter((p) => p.price > 100))
  }, [products])

  return <div>{/* ... */}</div>
}
```

**✅ DO: Calculate derived state directly**

```typescript
// ✅ Good: Derived state
function ProductList({ products }: { products: Product[] }) {
  const filteredProducts = products.filter((p) => p.price > 100)

  return <div>{/* ... */}</div>
}
```

### Anti-Pattern: Not Cleaning Up Effects

**❌ DON'T: Forget cleanup**

```typescript
// ❌ Bad: No cleanup
useEffect(() => {
  const subscription = subscribeToData((data) => {
    setData(data)
  })
  // Memory leak! Subscription never unsubscribed
}, [])
```

**✅ DO: Always clean up**

```typescript
// ✅ Good: Cleanup function
useEffect(() => {
  const subscription = subscribeToData((data) => {
    setData(data)
  })

  return () => {
    subscription.unsubscribe()  // Cleanup
  }
}, [])
```

### Anti-Pattern: Inconsistent Error Handling

**❌ DON'T: Mix error handling styles**

```typescript
// ❌ Bad: Inconsistent
async function fetchData() {
  try {
    const result = await api.getData()
    return result
  } catch {
    return null  // Sometimes returns null
  }
}

async function fetchOtherData() {
  const result = await api.getData()  // Sometimes throws
  return result
}
```

**✅ DO: Be consistent**

```typescript
// ✅ Good: Always throw errors
async function fetchData() {
  const result = await api.getData()  // Let errors propagate
  return result
}

// Handle at call site
try {
  const data = await fetchData()
} catch (error) {
  toast.error('Failed to fetch data')
}
```

---

## Summary: Key Takeaways

### Must-Haves
1. **Schema-first development** - Database schema as source of truth
2. **Type safety** - TypeScript strict mode, Zod validation
3. **Audit logging** - Track all changes
4. **Input validation** - Never trust user input
5. **Error boundaries** - Graceful error handling
6. **Testing** - Unit, integration, and E2E tests

### Code Quality
1. **Consistent patterns** - CRUD, file structure, naming
2. **Separation of concerns** - Queries vs mutations, layers
3. **Small components** - Single responsibility
4. **Explicit types** - No implicit any
5. **Documentation** - Through types and clear naming

### Security
1. **Authentication** - Required on all non-public routes
2. **Authorization** - Check permissions in API layer
3. **Sanitization** - Clean all user input
4. **Rate limiting** - Prevent abuse
5. **Security headers** - Defense in depth

### Performance
1. **Server Components** - Default choice
2. **Lazy loading** - Heavy components
3. **Image optimization** - Next.js Image
4. **Database indexes** - Based on query patterns
5. **Pagination** - For large datasets

---

**HISCOXNDS Examples:**

Every pattern in this guide is demonstrated in the HISCOXNDS codebase:
- Schema-driven development: All 30 tables
- CRUD patterns: All 30+ routers
- Audit logging: Every table + audit_logs
- Component structure: Entities, events, reinsurance modules
- Error handling: tRPC error formatting

**Use HISCOXNDS as reference** but **improve on its gaps**:
- Add testing (HISCOXNDS has none)
- Add error boundaries
- Add rate limiting
- Add security headers

---

**Version History:**
- v1.0 (2026-01-25) - Initial release based on HISCOXNDS patterns
