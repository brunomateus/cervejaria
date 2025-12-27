---
title: Retrospectiva 2025
date: 2024-12-31
categories: [Blogging, Retrospectiva]
tags: [retrospectiva]
img_path: 
---


### Retrospectiva 2025

Mais um ano se passou e vamos ao balanço cervejeiro de 2025.

#### Consumo

Tenho usado cada vez menos o <a href="http://www.untappd.com" target="_blank">Untappd</a>, mas vamos aos dados apontados por ele.

Em **2025**, bebi **103 novas cervejas**, de **53 estilos diferentes**,  ainda as **IPA - Imperial Doubel New England** foram as cervejas mais consumidas.

---

### Produção

O ano de **2025** foi menos ativo que **2024** devido a motivos de saúde. A meta era produzir uma cerveja por mês, e apesar de não ter alcançado a meta foi bom voltar a produzir com uma boa frequêcia.

Ao todos eu produzi **7 cervejas**:

* Italian Grape ale
* Catharina Sour
* Belgian Single
* Tripel
* Altbier
* Saison
* Belgian Dark Strong Ale


<div>
  <canvas id="mychart" style="width: 50% "></canvas>
</div>

Novamente fiquei satisfeito com a qualidade das cervejas que optei pro produzir. Me aventurei pela primeira vez no mundo das cerveja ácidas, voltei a produzir cervejas belgas que tanto adoro.

Além disso, ganhei minha primeira medalhe em concursos, no concurso [Cearense de Cervejas Caseiras 202](https://beerawardsplatform.com/concurso-cearense-de-cervejas-caseiras-2025), na categoria Dark British Beer com a Oatmeal Stout produzida no ano passado.

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<script>


const data = {
  labels: ['Lager', 'Ale'],
  datasets: [{
  label: 'Cervejas de 2025,
    data: [0, 6],
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
