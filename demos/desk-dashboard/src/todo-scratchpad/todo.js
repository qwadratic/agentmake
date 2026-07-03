// todo-scratchpad UI: mounts into #todo-panel .panel-body (app-shell contract).
document.addEventListener("DOMContentLoaded", () => {
  const body = document.querySelector("#todo-panel .panel-body");
  if (!body) return;

  const S = window.TodoStore;
  let todos = S.load(localStorage);

  body.innerHTML = "";
  const input = document.createElement("input");
  input.type = "text";
  input.className = "todo-input";
  input.placeholder = "Add a todo…";
  const list = document.createElement("ul");
  list.className = "todo-list";
  body.append(input, list);

  function commit(next) {
    todos = next;
    S.save(localStorage, todos);
    render();
  }

  function render() {
    list.innerHTML = "";
    todos.forEach((t, i) => {
      const li = document.createElement("li");
      li.className = "todo-item" + (t.done ? " done" : "");
      const span = document.createElement("span");
      span.className = "todo-text";
      span.textContent = t.text;
      span.addEventListener("click", () => commit(S.toggleTodo(todos, i)));
      const del = document.createElement("button");
      del.className = "todo-del";
      del.textContent = "✕";
      del.setAttribute("aria-label", "Delete todo");
      del.addEventListener("click", () => commit(S.removeTodo(todos, i)));
      li.append(span, del);
      list.appendChild(li);
    });
  }

  input.addEventListener("keydown", (e) => {
    if (e.key === "Enter") {
      commit(S.addTodo(todos, input.value));
      input.value = "";
    }
  });

  render();
});
