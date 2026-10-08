document.getElementById("btn").addEventListener("click", async () => {
  const out = document.getElementById("out");
  try {
    const res = await fetch("/api/launcher");
    const data = await res.json();
    out.textContent = data.message + "\n\n" + JSON.stringify(data, null, 2);
  } catch (e) {
    out.textContent = String(e);
  }
});
