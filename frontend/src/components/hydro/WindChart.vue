<template>
  <div class="wind-chart-container">
    <div class="wind-gauge" ref="gaugeRef"></div>
    <div class="wind-rose" ref="roseRef"></div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import axios from 'axios'

const gaugeRef = ref(null)
const roseRef = ref(null)
let gaugeChart = null
let roseChart = null

onMounted(async () => {
  initGaugeChart()
  await initRoseChart()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  if (gaugeChart) {
    gaugeChart.dispose()
  }
  if (roseChart) {
    roseChart.dispose()
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
        startAngle: 180,
        endAngle: 0,
        min: 0,
        max: 15,
        splitNumber: 5,
        itemStyle: {
          color: '#64b5f6'
        },
        progress: {
          show: true,
          width: 18,
          itemStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [
              { offset: 0, color: '#00e5ff' },
              { offset: 0.5, color: '#64b5f6' },
              { offset: 1, color: '#ff5252' }
            ])
          }
        },
        pointer: {
          length: '70%',
          width: 6,
          itemStyle: {
            color: '#fff'
          }
        },
        axisLine: {
          lineStyle: {
            width: 18,
            color: [[1, 'rgba(100, 181, 246, 0.2)']]
          }
        },
        axisTick: {
          distance: -24,
          splitNumber: 5,
          lineStyle: {
            width: 2,
            color: '#64b5f6'
          }
        },
        splitLine: {
          distance: -28,
          length: 14,
          lineStyle: {
            width: 3,
            color: '#64b5f6'
          }
        },
        axisLabel: {
          distance: -50,
          color: '#90caf9',
          fontSize: 12
        },
        anchor: {
          show: true,
          showAbove: true,
          size: 20,
          itemStyle: {
            borderWidth: 5,
            borderColor: '#64b5f6'
          }
        },
        title: {
          show: false
        },
        detail: {
          valueAnimation: true,
          fontSize: 24,
          offsetCenter: [0, '70%'],
          formatter: '{value} m/s',
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

const initRoseChart = async () => {
  if (!roseRef.value) return
  
  roseChart = echarts.init(roseRef.value)
  
  try {
    const response = await axios.get('http://localhost:3000/api/hydro/wind-rose')
    const windRoseData = response.data.data
    
    const option = {
      backgroundColor: 'transparent',
      title: {
        text: '风向分布',
        left: 'center',
        top: 10,
        textStyle: {
          color: '#90caf9',
          fontSize: 14
        }
      },
      polar: {
        radius: '70%'
      },
      angleAxis: {
        type: 'category',
        data: windRoseData.map(d => d.direction),
        startAngle: 90,
        axisLine: {
          lineStyle: {
            color: '#64b5f6'
          }
        },
        axisLabel: {
          color: '#90caf9'
        }
      },
      radiusAxis: {
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
            color: 'rgba(100, 181, 246, 0.2)'
          }
        }
      },
      tooltip: {
        backgroundColor: 'rgba(10, 25, 41, 0.9)',
        borderColor: '#64b5f6',
        textStyle: {
          color: '#fff'
        }
      },
      series: [
        {
          type: 'bar',
          data: windRoseData.map(d => d.frequency),
          coordinateSystem: 'polar',
          itemStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: '#64b5f6' },
              { offset: 1, color: '#00e5ff' }
            ])
          },
          label: {
            show: false
          }
        }
      ]
    }
    
    roseChart.setOption(option)
  } catch (error) {
    console.error('获取风向玫瑰图数据失败:', error)
  }
}

const updateData = (windData) => {
  if (!windData || !gaugeChart) return
  
  gaugeChart.setOption({
    series: [
      {
        data: [
          {
            value: parseFloat(windData.speed)
          }
        ]
      }
    ]
  })
}

const handleResize = () => {
  if (gaugeChart) {
    gaugeChart.resize()
  }
  if (roseChart) {
    roseChart.resize()
  }
}

defineExpose({ updateData })
</script>

<style scoped>
.wind-chart-container {
  display: flex;
  gap: 20px;
  height: 320px;
}

.wind-gauge {
  flex: 1;
  height: 100%;
}

.wind-rose {
  flex: 1;
  height: 100%;
}
</style>


