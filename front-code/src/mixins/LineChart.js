import { Line, mixins } from 'vue-chartjs'
const { reactiveProp } = mixins

export default {
    extends: Line,
    mixins: [reactiveProp],
    props: {
        height: {
            default: 90,
            type: Number
        }
    },
    mounted () {
    // this.chartData is created in the mixin.
    // If you want to pass options please create a local options object
        this.renderChart()
    }
}