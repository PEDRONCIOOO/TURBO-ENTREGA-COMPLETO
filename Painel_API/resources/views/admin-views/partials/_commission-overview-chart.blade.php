@php($params = session('dash_params'))
<div id="grow-sale-chart"></div>

<script>
    "use strict";
    options = {
          series: [{
          name: 'Gross Sale',
          data: [{{ implode(",",$data['total_sell']) }}]
        },{
          name: 'Admin Comission',
          data: [{{ implode(",",$data['commission']) }}]
        },{
          name: 'Delivery Comission',
          data: [{{ implode(",",$data['delivery_commission']) }}]
        }],
          chart: {
          height: 350,
          type: 'area',
          toolbar: {
            show:false
        },
            colors: ['#76ffcd','#ff6d6d', '#000000'],
        },
            colors: ['#76ffcd','#ff6d6d', '#000000'],
        dataLabels: {
          enabled: false,
            colors: ['#76ffcd','#ff6d6d', '#000000'],
        },
        stroke: {
          curve: 'smooth',
          width: 2,
            colors: ['#76ffcd','#ff6d6d', '#000000'],
        },
        fill: {
            type: 'gradient',
            colors: ['#76ffcd','#ff6d6d', '#000000'],
        },
        xaxis: {
        //   type: 'datetime',
            categories: [{!! implode(",",$data['label']) !!}]
        },
        tooltip: {
          x: {
            format: 'dd/MM/yy HH:mm'
          },
        },
        };

        chart = new ApexCharts(document.querySelector("#grow-sale-chart"), options);
        chart.render();

        // INITIALIZATION OF CHARTJS
        // =======================================================
        Chart.plugins.unregister(ChartDataLabels);

        $('.js-chart').each(function () {
            $.HSCore.components.HSChartJS.init($(this));
        });

        updatingChart = $.HSCore.components.HSChartJS.init($('#updatingData'));
    </script>
