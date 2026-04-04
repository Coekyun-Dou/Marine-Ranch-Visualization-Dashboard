<template>
  <div class="wave-chart" ref="chartRef"></div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'

const chartRef = ref(null)
let chart = null
let waveHeightData = []
let wavePeriodData = []
let timeData = []
const MAX_DATA = 30

onMounted(() => {
  initChart()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  if (chart) {
    chart.dispose()
  }
  window.removeEventListener('resize', handleResize)
})

const initChart = () => {
  if (!chartRef.value) return
  
  chart = echarts.init(chartRef.value)
  
  const option = {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      backgroundColor: 'rgba(10, 25, 41, 0.9)',
      borderColor: '#64b5f6',
      textStyle: {
        color: '#fff'
      }
    },
    legend: {
      data: ['波高', '周期'],
      textStyle: {
        color: '#90caf9'
      },
      top: 10
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      top: '15%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: timeData,
      boundaryGap: false,
      axisLine: {
        lineStyle: {
          color: '#64b5f6'
        }
      },
      axisLabel: {
        color: '#90caf9'
      }
    },
    yAxis: [
      {
        type: 'value',
        name: '波高(米)',
        position: 'left',
        axisLine: {
          lineStyle: {
            color: '#64b5f6'
          }
        },
        axisLabel: {
          color: '#90caf9'
        },
        splitLine: {
          lineStyle: {
            color: 'rgba(100, 181, 246, 0.1)'
          }
        }
      },
      {
        type: 'value',
        name: '周期(秒)',
        position: 'right',
        axisLine: {
          lineStyle: {
            color: '#00e5ff'
          }
        },
        axisLabel: {
          color: '#00e5ff'
        },
        splitLine: {
          show: false
        }
      }
    ],
    series: [
      {
        name: '波高',
        type: 'line',
        smooth: true,
        data: waveHeightData,
        itemStyle: {
          color: '#64b5f6'
        },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(100, 181, 246, 0.5)' },
            { offset: 1, color: 'rgba(100, 181, 246, 0.1)' }
          ])
        },
        yAxisIndex: 0
      },
      {
        name: '周期',
        type: 'line',
        smooth: true,
        data: wavePeriodData,
        itemStyle: {
          color: '#00e5ff'
        },
        yAxisIndex: 1
      }
    ]
  }
  
  chart.setOption(option)
}

const updateData = (waveData) => {
  if (!waveData) return
  
  const now = new Date()
  const timeStr = now.toLocaleTimeString()
  
  timeData.push(timeStr)
  waveHeightData.push(parseFloat(waveData.height))
  wavePeriodData.push(parseFloat(waveData.period))
  
  if (timeData.length > MAX_DATA) {
    timeData.shift()
    waveHeightData.shift()
    wavePeriodData.shift()
  }
  
  if (chart) {
    chart.setOption({
      xAxis: {
        data: timeData
      },
      series: [
        { data: waveHeightData },
        { data: wavePeriodData }
      ]
    })
  }
}

const handleResize = () => {
  if (chart) {
    chart.resize()
  }
}

defineExpose({ updateData })
</script>

<style scoped>
.wave-chart {
  width: 100%;
  height: 320px;
}
</style>


