const pseudos = ["NeonSkid", "TurboZ", "Toi", "ShadowDrift"];

document.getElementById("btn").addEventListener("click", () => {
  const pick = pseudos[Math.floor(Math.random() * pseudos.length)];
  document.getElementById("out").textContent =
    pick + " est sur la grille — rendez-vous en piste !";
});
