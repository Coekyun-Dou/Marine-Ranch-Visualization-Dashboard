<template>
  <div class="tide-chart" ref="chartRef"></div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import axios from 'axios'

const chartRef = ref(null)
let chart = null

onMounted(async () => {
  await initChart()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  if (chart) {
    chart.dispose()
  }
  window.removeEventListener('resize', handleResize)
})

const initChart = async () => {
  if (!chartRef.value) return
  
  chart = echarts.init(chartRef.value)
  
  // 从后端获取24小时潮位数据
  try {
    const response = await axios.get('http://localhost:3000/api/hydro/tide-history')
    const tideData = response.data.data
    
    const times = tideData.map(d => d.time)
    const levels = tideData.map(d => parseFloat(d.level))
    
    const option = {
      backgroundColor: 'transparent',
      tooltip: {
        trigger: 'axis',
        backgroundColor: 'rgba(10, 25, 41, 0.9)',
        borderColor: '#64b5f6',
        textStyle: {
          color: '#fff'
        },
        formatter: (params) => {
          const p = params[0]
          return `${p.name}<br/>潮位: ${p.value} 米`
        }
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '3%',
        top: '10%',
        containLabel: true
      },
      xAxis: {
        type: 'category',
        data: times,
        boundaryGap: false,
        axisLine: {
          lineStyle: {
            color: '#64b5f6'
          }
        },
        axisLabel: {
          color: '#90caf9',
          interval: 3 // 每隔3小时显示一次
        }
      },
      yAxis: {
        type: 'value',
        name: '潮位(米)',
        min: 0,
        max: 5,
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
      series: [
        {
          name: '潮位',
          type: 'line',
          smooth: true,
          data: levels,
          itemStyle: {
            color: '#ffd54f'
          },
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: 'rgba(255, 213, 79, 0.5)' },
              { offset: 1, color: 'rgba(255, 213, 79, 0.1)' }
            ])
          },
          markLine: {
            silent: true,
            lineStyle: {
              color: '#ff5252',
              type: 'dashed'
            },
            data: [
              { yAxis: 2.5, label: { formatter: '平均海平面' } }
            ]
          },
          markPoint: {
            data: [
              { type: 'max', name: '高潮' },
              { type: 'min', name: '低潮' }
            ],
            itemStyle: {
              color: '#ffd54f'
            }
          }
        }
      ]
    }
    
    chart.setOption(option)
  } catch (error) {
    console.error('获取潮位数据失败:', error)
  }
}

const handleResize = () => {
  if (chart) {
    chart.resize()
  }
}
</script>

<style scoped>
.tide-chart {
  width: 100%;
  height: 320px;
}
</style>


