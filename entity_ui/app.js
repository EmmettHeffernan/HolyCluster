let lastNode="";

async function update(){
  try{
    const r = await fetch("state.json?t=" + Date.now());
    const s = await r.json();

    document.body.className = (s.active_node === "ARCHIVE-09" ? "archive" : "cortex");

    if(lastNode && lastNode !== s.active_node){
      document.body.classList.add("glitch");
      setTimeout(() => document.body.classList.remove("glitch"), 450);
    }

    lastNode = s.active_node;

    document.getElementById("node").textContent = s.active_node;
    document.getElementById("state").textContent = s.state;
    document.getElementById("coh").textContent = s.coherence + "%";
    document.getElementById("msg").textContent = s.message;
    document.getElementById("archive").textContent = s.archive;
    document.getElementById("cortex").textContent = s.cortex;
    document.getElementById("bar").style.setProperty("--v", s.coherence + "%");
  }catch(e){}
}

setInterval(update, 500);
update();
