<template>
  <div class="light-chart-container">
    <div class="light-gauge" ref="gaugeRef"></div>
    <div class="light-trend" ref="trendRef"></div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'

const gaugeRef = ref(null)
const trendRef = ref(null)
let gaugeChart = null
let trendChart = null
let lightData = []
let uvData = []
let timeData = []
const MAX_DATA = 30

onMounted(() => {
  initGaugeChart()
  initTrendChart()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  if (gaugeChart) {
    gaugeChart.dispose()
  }
  if (trendChart) {
    trendChart.dispose()
  }
  window.removeEventListener('resize', handleResize)
})

const initGaugeChart = () => {
  if (!gaugeRef.value) return
  
  gaugeChart = echarts.init(gaugeRef.value)
  
  const option = {
    backgroundColor: 'transparent',
    series: [
      {
        type: 'gauge',
        center: ['50%', '60%'],
        startAngle: 200,
        endAngle: -20,
        min: 0,
        max: 1200,
        splitNumber: 6,
        itemStyle: {
          color: '#ffd54f'
        },
        progress: {
          show: true,
          width: 20,
          itemStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [
              { offset: 0, color: '#ff9800' },
              { offset: 0.5, color: '#ffd54f' },
              { offset: 1, color: '#ffeb3b' }
            ])
          }
        },
        pointer: {
          length: '60%',
          width: 6,
          itemStyle: {
            color: '#fff'
          }
        },
        axisLine: {
          lineStyle: {
            width: 20,
            color: [[1, 'rgba(255, 213, 79, 0.2)']]
          }
        },
        axisTick: {
          distance: -26,
          splitNumber: 5,
          lineStyle: {
            width: 2,
            color: '#ffd54f'
          }
        },
        splitLine: {
          distance: -30,
          length: 14,
          lineStyle: {
            width: 3,
            color: '#ffd54f'
          }
        },
        axisLabel: {
          distance: -50,
          color: '#ffeb3b',
          fontSize: 12
        },
        anchor: {
          show: true,
          showAbove: true,
          size: 18,
          itemStyle: {
            borderWidth: 4,
            borderColor: '#ffd54f'
          }
        },
        title: {
          show: false
        },
        detail: {
          valueAnimation: true,
          fontSize: 24,
          offsetCenter: [0, '80%'],
          formatter: '{value} lux',
          color: '#fff'
        },
        data: [
          {
            value: 0
          }
        ]
      }
    ]
  }
  
  gaugeChart.setOption(option)
}

const initTrendChart = () => {
  if (!trendRef.value) return
  
  trendChart = echarts.init(trendRef.value)
  
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
      data: ['光照强度', 'UV指数'],
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
        name: '光照(lux)',
        position: 'left',
        axisLine: {
          lineStyle: {
            color: '#ffd54f'
          }
        },
        axisLabel: {
          color: '#ffd54f'
        },
        splitLine: {
          lineStyle: {
            color: 'rgba(100, 181, 246, 0.1)'
          }
        }
      },
      {
        type: 'value',
        name: 'UV指数',
        position: 'right',
        axisLine: {
          lineStyle: {
            color: '#ff5252'
          }
        },
        axisLabel: {
          color: '#ff5252'
        },
        splitLine: {
          show: false
        }
      }
    ],
    series: [
      {
        name: '光照强度',
        type: 'line',
        smooth: true,
        data: lightData,
        itemStyle: {
          color: '#ffd54f'
        },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(255, 213, 79, 0.5)' },
            { offset: 1, color: 'rgba(255, 213, 79, 0.1)' }
          ])
        },
        yAxisIndex: 0
      },
      {
        name: 'UV指数',
        type: 'line',
        smooth: true,
        data: uvData,
        itemStyle: {
          color: '#ff5252'
        },
        yAxisIndex: 1
      }
    ]
  }
  
  trendChart.setOption(option)
}

const updateData = (lightDataObj) => {
  if (!lightDataObj) return
  
  const now = new Date()
  const timeStr = now.toLocaleTimeString()
  
  timeData.push(timeStr)
  lightData.push(parseInt(lightDataObj.intensity))
  uvData.push(parseFloat(lightDataObj.uv))
  
  if (timeData.length > MAX_DATA) {
    timeData.shift()
    lightData.shift()
    uvData.shift()
  }
  
  // 更新仪表盘
  if (gaugeChart) {
    gaugeChart.setOption({
      series: [
        {
          data: [
            {
              value: parseInt(lightDataObj.intensity)
            }
          ]
        }
      ]
    })
  }
  
  // 更新趋势图
  if (trendChart) {
    trendChart.setOption({
      xAxis: {
        data: timeData
      },
      series: [
        { data: lightData },
        { data: uvData }
      ]
    })
  }
}

const handleResize = () => {
  if (gaugeChart) {
    gaugeChart.resize()
  }
  if (trendChart) {
    trendChart.resize()
  }
}

defineExpose({ updateData })
</script>

<style scoped>
.light-chart-container {
  display: flex;
  gap: 20px;
  height: 320px;
}

.light-gauge {
  width: 400px;
  height: 100%;
}

.light-trend {
  flex: 1;
  height: 100%;
}
</style>


