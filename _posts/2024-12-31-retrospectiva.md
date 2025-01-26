---
title: Retrospectiva 2024
date: 2024-12-31
categories: [Blogging, Retrospectiva]
tags: [retrospectiva]
img_path: 
---


### Retrospectiva 2024

Mais um ano se passou e vamos ao balanço cervejeiro de 2024.

#### Consumo

Tenho usado cada vez menos o <a href="untappd.com" target="_blank">Untappd</a>, mas vamos aos dados apontados por ele.

Em **2024**, bebi **101 novas cervejas**, de **55 estilos diferentes**,  ainda as **IPAs** foram as cervejas mais consumidas. As cervejas consumidas foram distribuídas em **44 cervejarias**. Devido ao clube <a href="https://hopmundi.com.br/vintage-hop/"> Vintage Hop</a>, a **HopMundi** foi a cervejaria mais consumida no ano.

---

### Produção

O ano de **2024** foi bem ativo. A meta era produzir uma cerveja por mês, e apesar de não ter alcançado a meta eu fiquei bastante contente.

Ao todos eu produzi **8 cervejas**:

* American Pale
* Weiss Beer
* Red ale 2x
* Bohemian Pilsner
* Baltic Porter
* Oatmeal Stout
* Vienna Lager


<div>
  <canvas id="mychart" style="width: 50% "></canvas>
</div>

Também fique bastante satisfeito com a qualidade das cervejas produzidas. 

Participei de **2 concursos**: Nacional das Acervas e um concurso local que me deu direito a participar do Copa das Acervas de 2025.

A medalha ainda não veio, mas os resultados estão melhorando. Consegui uma nota **40** pela primeira vez.

É isso pessoal. 2025 vem aí, espero que a produção continue a todo vapor.

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<script>


const data = {
  labels: ['Lager', 'Ale'],
  datasets: [{
  label: 'Cervejas de 2024',
    data: [2, 6],
    backgroundColor: [
      'rgb(255, 99, 132)',
      'rgb(54, 162, 235)',
      'rgb(255, 205, 86)'
    ],
    hoverOffset: 4
  }]
};


const config = {
  type: 'doughnut',
  data: data,
  options: {
    responsive: true,
    plugins: {
      legend: {
        position: 'top',
      },
      title: {
        display: true,
        text: 'Ale vs Lager'
      }
    }
  },
};

new Chart(document.getElementById('mychart'), config)

</script>
