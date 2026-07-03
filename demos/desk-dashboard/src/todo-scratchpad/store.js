// todo-scratchpad store: pure functions on plain array of {text, done}.
// Works in browser (script tag) and node (module.exports).

const STORAGE_KEY = "desk-dashboard.todos";

function addTodo(todos, text) {
  const t = String(text).trim();
  if (!t) return todos;
  return todos.concat([{ text: t, done: false }]);
}

function toggleTodo(todos, index) {
  return todos.map((t, i) => (i === index ? { text: t.text, done: !t.done } : t));
}

function removeTodo(todos, index) {
  return todos.filter((_, i) => i !== index);
}

function serialize(todos) {
  return JSON.stringify(todos);
}

function deserialize(raw) {
  try {
    const v = JSON.parse(raw);
    if (!Array.isArray(v)) return [];
    return v
      .filter((t) => t && typeof t.text === "string")
      .map((t) => ({ text: t.text, done: !!t.done }));
  } catch {
    return [];
  }
}

function save(storage, todos) {
  storage.setItem(STORAGE_KEY, serialize(todos));
}

function load(storage) {
  return deserialize(storage.getItem(STORAGE_KEY));
}

const TodoStore = { STORAGE_KEY, addTodo, toggleTodo, removeTodo, serialize, deserialize, save, load };

if (typeof module !== "undefined" && module.exports) module.exports = TodoStore;
if (typeof window !== "undefined") window.TodoStore = TodoStore;
