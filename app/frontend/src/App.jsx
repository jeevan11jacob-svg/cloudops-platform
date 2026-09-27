import { useEffect, useState } from "react";

function App() {
  const [tasks, setTasks] = useState([]);
  const [title, setTitle] = useState("");

  const loadTasks = async () => {
    const response = await fetch("/api/tasks");
    const data = await response.json();
    setTasks(data);
  };

  useEffect(() => {
    loadTasks();
  }, []);

  const addTask = async (event) => {
    event.preventDefault();

    if (!title.trim()) {
      return;
    }

    await fetch("/api/tasks", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ title })
    });

    setTitle("");
    loadTasks();
  };

  return (
    <div style={{ maxWidth: "700px", margin: "50px auto", padding: "20px" }}>
      <h1>CloudOps Task Manager</h1>
      <p>Running on Kubernetes ??</p>

      <form onSubmit={addTask}>
        <input
          value={title}
          onChange={(event) => setTitle(event.target.value)}
          placeholder="Enter a task"
          style={{ padding: "10px", width: "70%" }}
        />
        <button type="submit" style={{ padding: "10px", marginLeft: "10px" }}>
          Add Task
        </button>
      </form>

      <ul>
        {tasks.map((task) => (
          <li key={task._id} style={{ marginTop: "15px" }}>
            {task.title}
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;
