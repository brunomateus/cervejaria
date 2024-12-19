---
layout: post
categories: [Concursos]
---

{% assign av1Total = page.av1.aroma  | plus: page.av1.aparencia | plus: page.av1.sabor | plus: page.av1.boca | plus: page.av1.geral %}
{% assign av2Total = page.av2.aroma  | plus: page.av2.aparencia | plus: page.av2.sabor | plus: page.av2.boca | plus: page.av2.geral %}
{% assign av3Total = page.av3.aroma  | plus: page.av3.aparencia | plus: page.av3.sabor | plus: page.av3.boca | plus: page.av3.geral %}

{% assign number_of_evaluations = 0 %}
{% if page.av1 %}
  {% assign number_of_evaluations = number_of_evaluations | plus: 1 %}
{% endif %}
{% if page.av2 %}
 {% assign number_of_evaluations = number_of_evaluations | plus: 1 %}
{% endif %}
{% if page.av3 %}
 {% assign number_of_evaluations = number_of_evaluations | plus: 1 %}
{% endif %}

{% assign nota = av1Total | plus: av2Total | plus: av3Total | divided_by: 3 %}

<article>
    <header>
        <h1 class="my-2"><i class="fa fa-medal"></i> Concurso: <span class="text-muted">{{ page.concurso }}</span></h1>
        <h1 class="my-2"><i class="fa fa-beer"></i> Cerveja julgada: <span class="text-muted">{{ page.cerveja }}</span></h1>
        <h1 class="my-2"><i class="fa fa-envelope-open-text"></i> Nota final: <span class="text-muted">{{ nota }}</span></h1>
    </header>

    <hr>
    
    <h2>Detalhamento</h2>

    <table class="table-wrapper">
        <caption>Detalhamento das notas dos avaliadores</caption>
        <thead>
            <tr>
                <th>Avaliador</th>
                <th>Aroma</th>
                <th>Aparência</th>
                <th>Sabor</th>
                <th>Sensação de boca</th>
                <th>Geral</th>
                <th>Pontuação total</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td> Avaliador 01 </td>
                <td class="text-center"> {{ page.av1.aroma }}/12 </td>
                <td class="text-center"> {{page.av1.aparencia }}/3 </td>
                <td class="text-center"> {{page.av1.sabor }}/20 </td>
                <td class="text-center"> {{ page.av1.boca }}/5 </td>
                <td class="text-center"> {{page.av1.geral }}/10 </td>
                <td class="text-center font-weight-bold"> {{av1Total}} </td>
            </tr>
{% if page.av2 %}
            <tr>
                <td> Avaliador 02 </td>
                <td class="text-center"> {{ page.av2.aroma }}/12 </td>
                <td class="text-center"> {{page.av2.aparencia }}/3 </td>
                <td class="text-center"> {{page.av2.sabor }}/20 </td>
                <td class="text-center"> {{ page.av2.boca }}/5 </td>
                <td class="text-center"> {{page.av2.geral }}/10 </td>
                <td class="text-center font-weight-bold"> {{av2Total}} </td>
            </tr>
{% endif %}
{% if page.av3 %}
            <tr>
                <td> Avaliador 03 </td>
                <td class="text-center"> {{ page.av3.aroma }}/12 </td>
                <td class="text-center"> {{page.av3.aparencia }}/3 </td>
                <td class="text-center"> {{page.av3.sabor }}/20 </td>
                <td class="text-center"> {{ page.av3.boca }}/5 </td>
                <td class="text-center"> {{page.av3.geral }}/10 </td>
                <td class="text-center font-weight-bold"> {{av3Total}} </td>
            </tr>
{% endif %}
        </tbody>
    </table>
</article>

<div>
  <canvas id="radar"></canvas>
</div>

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<!--
<script>
  const ctx = document.getElementById('myChart');

  new Chart(ctx, {
    type: 'bar',
    options: {
      plugins: {
        title: {
          display: true,
          text: 'Avaliação dos juízes'
        },
      },
    },
    data: {
      labels: ['Avaliador 01', 'Avaliador 02', 'Avaliador 03'],
      datasets: [{
        label: 'Aroma',
        data: [{{ page.av1.aroma }}, {{ page.av2.aroma }}, {{ page.av3.aroma}}],
        borderWidth: 1
      },
      {
          label: 'Sabor',
          data: [{{ page.av1.sabor }}, {{ page.av2.sabor }}, {{ page.av3.sabor }}],
          borderWidth: 1
      },
      {
          label: 'Aparência',
          data: [{{ page.av1.aparencia }}, {{ page.av2.aparencia }}, {{ page.av3.aparencia }}],
          borderWidth: 1
      },
      {
          label: 'Sensação na boca',
          data: [{{ page.av1.boca }}, {{ page.av2.boca }}, {{ page.av3.boca }}],
          borderWidth: 1
      },
      {
          label: 'Geral',
          data: [{{ page.av1.geral }}, {{ page.av2.geral }}, {{ page.av3.geral }}],
          borderWidth: 1
      }],
    },
    options: {
      scales: {
        x: {
          stacked: true
        },
        y: {
          stacked: true
        },
      }
    }
  });
</script>
-->

<script>

const data = {
  labels: [
  'Aroma',
  'Aparência',
  'Sabor',
  'Sensação na boca',
  'Geral'
  ],
  datasets: [],
};

{% if page.av1 %}
  data.datasets.push(
  {
    label: 'Avaliador 1',
    data: [({{ page.av1.aroma }}/12)*100, ({{ page.av1.aparencia }}/3)*100, ({{ page.av1.sabor }}/20)*100, ({{ page.av1.boca }}/5)*100, ({{ page.av1.geral }}/10)*100],
    fill: true,
  });
{% endif %}

{% if page.av2 %}
  data.datasets.push(
  {
    label: 'Avaliador 1',
    data: [({{ page.av2.aroma }}/12)*100, ({{ page.av2.aparencia }}/3)*100, ({{ page.av2.sabor }}/20)*100, ({{ page.av2.boca }}/5)*100, ({{ page.av2.geral }}/10)*100],
    fill: true,
  });
{% endif %}

{% if page.av3 %}
  data.datasets.push(
  {
    label: 'Avaliador 1',
    data: [({{ page.av3.aroma }}/12)*100, ({{ page.av3.aparencia }}/3)*100, ({{ page.av3.sabor }}/20)*100, ({{ page.av3.boca }}/5)*100, ({{ page.av3.geral }}/10)*100],
    fill: true,
  });
{% endif %}
const config = {
  type: 'radar',
  data: data,
  options: {
    elements: {
      line: {
        borderWidth: 3
      }
    },
    scales: {
      r: {
        suggestedMin: 0
      }
    }
  },
};

new Chart(document.getElementById('radar'), config)

</script>

{{ content }}
