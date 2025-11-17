# n8n Code Node Patterns & Best Practices

## Common Issues and Solutions

### ❌ DO NOT: Modify Input Items Directly

This will cause "Unknown error":

```javascript
// WRONG - This fails because input items are immutable
for (const item of $input.all()) {
  item.json.myNewField = 1; // ❌ Error!
}
return $input.all();
```

### ✅ DO: Create New Objects

```javascript
// CORRECT - Create new objects with spread operator
const items = $input.all();
return items.map(item => ({
  json: {
    ...item.json,
    myNewField: 1
  }
}));
```

## Single Item vs Multiple Items

### Single Item Processing (most common for webhooks)

```javascript
// Access single item data
const inputData = $input.item.json;

// Return single item
return {
  json: {
    field1: 'value1',
    field2: 'value2'
  }
};
```

### Multiple Items Processing

```javascript
// Access all items
const items = $input.all();

// Process and return array of items
return items.map(item => ({
  json: {
    ...item.json,
    newField: 'newValue'
  }
}));
```

## Accessing Webhook Data

Webhook data is nested under the `body` property:

```javascript
// Extract webhook data safely
const inputData = $input.item.json;
const body = inputData.body || inputData;

// Access fields from body
const message = body.message;
const sessionId = body.sessionId || 'default-session';
```

## Error Handling

Always validate required fields:

```javascript
const body = $input.item.json.body || $input.item.json;

if (!body.message) {
  throw new Error('Message is required');
}

return {
  json: {
    message: body.message,
    processed: true
  }
};
```

## Accessing Data from Previous Nodes

```javascript
// Get data from a specific previous node
const previousNodeData = $('Node Name').first().json;

// Access specific fields
const sessionId = previousNodeData.sessionId;
const userMessage = previousNodeData.userMessage;
```

## Common Patterns

### 1. Extract and Transform Webhook Data

```javascript
const inputData = $input.item.json;
const body = inputData.body || inputData;

return {
  json: {
    id: body.id || `generated-${Date.now()}`,
    message: body.message,
    timestamp: new Date().toISOString()
  }
};
```

### 2. Merge Data from Multiple Sources

```javascript
// Get data from previous node
const previousData = $('Previous Node').first().json;

// Get current input
const currentData = $input.item.json;

// Merge both
return {
  json: {
    ...previousData,
    ...currentData,
    processed: true
  }
};
```

### 3. Conditional Data Processing

```javascript
const body = $input.item.json.body || $input.item.json;
const message = body.message.toLowerCase();

const isUrgent = ['urgent', 'emergency', 'help'].some(keyword =>
  message.includes(keyword)
);

return {
  json: {
    originalMessage: body.message,
    isUrgent: isUrgent,
    priority: isUrgent ? 'high' : 'normal'
  }
};
```

## Debugging Tips

1. **Log the input structure**:
   ```javascript
   console.log('Input:', JSON.stringify($input.item.json, null, 2));
   ```

2. **Check for undefined values**:
   ```javascript
   const body = $input.item.json.body;
   if (!body) {
     throw new Error('No body found in input');
   }
   ```

3. **Use fallback values**:
   ```javascript
   const sessionId = body.sessionId || body.id || `session-${Date.now()}`;
   ```

## References

- [n8n Code Node Documentation](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.code/)
- [n8n Expression Resolution](https://docs.n8n.io/code-examples/expressions/)
