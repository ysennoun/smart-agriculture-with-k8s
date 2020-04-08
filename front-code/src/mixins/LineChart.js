import { Line, mixins } from 'vue-chartjs'
const { reactiveProp } = mixins

export default {
    extends: Line,
    mixins: [reactiveProp],
    props: {
        height: {
            default: 90,
            type: Number
        },
        chartOptions: {
            chart: {
                id: 'vuechart-example'
            },
            xaxis: {
                categories: [1991, 1992, 1993, 1994, 1995]
            }
        }
    },
    mounted () {
    // this.chartData is created in the mixin.
    // If you want to pass options please create a local options object
        this.renderChart(this.height, this.chartOptions)
    }
}