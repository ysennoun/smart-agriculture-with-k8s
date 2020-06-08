<template>
    <b-container fluid>
        <b-row class="mt-2">
            <b-col>
                <div id="card-device-value" class="card">
                    <h5 class="card-header border-light text-center"><b-icon-display-fill></b-icon-display-fill> &nbsp; Device</h5>
                    <div id="card-body-device-value" class="card-body text-center">
                        <h2 class="card-title mb-0">{{deviceName}}</h2>
                    </div>
                </div>            
            </b-col>
            <b-col>
                <div id="card-temperature-value" class="card">
                    <h5 class="card-header border-light text-center"><b-icon-sun></b-icon-sun> &nbsp; Last Temperature</h5>
                    <div id="card-body-temperature-value" class="card-body text-center">
                        <h2 class="card-title mb-0">{{lastTemperature}}</h2>
                        <p class="card-text">{{lastDate}}</p>
                    </div>
                </div>            
            </b-col>
            <b-col>
                <div id="card-moisture-value" class="card">
                    <h5 class="card-header border-light text-center"><b-icon-droplet-fill></b-icon-droplet-fill> &nbsp; Last Moisture</h5>
                    <div id="card-body-moisture-value" class="card-body text-center">
                        <h2 class="card-title mb-0">{{lastMoisture}}</h2>
                        <p class="card-text">{{lastDate}}</p>
                    </div>
                </div>            
            </b-col>
        </b-row>
        <b-row class="mt-2">
            <b-col>
                 <div id="card-temperature-timeseries" class="card">
                    <h5 id="card-header-temperature-timeseries" class="card-header">Temperatures (°C) over the past 7 days</h5>
                    <div>
                        <line-chart :chart-data="temperatureData"></line-chart>
                    </div>
                </div>                 
            </b-col>
        </b-row>
        <b-row class="mt-2">
            <b-col>
                 <div id="card-moisture-timeseries" class="card">
                    <h5 id="card-header-moisture-timeseries" class="card-header">Moisture (%) over the past 7 days</h5>
                    <div>
                        <line-chart :chart-data="moistureData"></line-chart>
                    </div>
                </div>                 
            </b-col>
        </b-row>
    </b-container>
</template>

<script>
import axios from "axios";
import LineChart from './../mixins/LineChart.js'

const API_URL = process.env.VUE_APP_API_URL

export default {
    components: {
        LineChart,
    },
    data() {
        return {
            deviceName: null,
            temperatureData: {labels: [], datasets: []},
            moistureData: {labels: [], datasets: []},
            lastDate: null,
            lastTemperature: null,
            lastMoisture: null,
            header: {}
        }
    },
    methods: {
        getQueryParams() {
            var today = new Date();
            var oneWeekAgo = new Date();
            var pastDate = oneWeekAgo.getDate() - 7;
            oneWeekAgo.setDate(pastDate);
            return "?from_date=" + today.toISOString().slice(0,-5)+"Z" + "&to_date=" + oneWeekAgo.toISOString().slice(0,-5)+"Z"
        },
        setCharts: function(deviceName) {
            this.deviceName =  deviceName;
            this.getLastValueData();
            this.getTimeseriesData();
            setInterval(this.getLastValueData, 5000)
            setInterval(this.getTimeseriesData, 5000)
        },
        getLastValueData() {
            var url = API_URL + "/devices/" + this.deviceName + "/lastValue"
            console.log(url)
            axios.get(
                    url,
                    {
                        auth: {
                            username: this.$store.getters.getCredentials.login,
                            password: this.$store.getters.getCredentials.password
                        }
                    }
                )
                .then(response => {
                    console.log(response)
                    var lastValue = response.data
                    this.lastDate = lastValue.rows[0].timestamp
                    this.lastTemperature = lastValue.rows[0].temperature + "°C"
                    this.lastMoisture = lastValue.rows[0].moisture + "%"
                })
                .catch(err => {
                    if(err.response && err.response.status == 401) {
                        console.log('Failed to login')
                        this.sendAuthenticationFailed();
                    }
                });
        },
        getTimeseriesData() {
            var url = API_URL + "/devices/" + this.deviceName + "/timeseries" + this.getQueryParams()
            console.log(url)
            axios.get(
                    url,
                    {
                        auth: {
                            username: this.$store.getters.getCredentials.login,
                            password: this.$store.getters.getCredentials.password
                        }
                    }
                )
                .then(response => {
                    console.log(response.data)
                    var timeseries = response.data
                    var timestamps = []
                    var temperatures = []
                    var moistures = []
                    timeseries.rows.forEach(element => {
                        timestamps.push(element.timestamp)
                        temperatures.push(element.temperature)
                        moistures.push(element.moisture)
                    });
                    this.temperatureData = {
                        labels: timestamps,
                        datasets: [
                        {
                            label: 'Temperature',
                            borderColor: '#d77c7c',
                            backgroundColor: 'rgba(225,157,157, 0.5)',
                            fill: true,
                            data: temperatures
                        }]
                    };
                    this.moistureData = {
                        labels: timestamps,
                        datasets: [
                        {
                            label: 'Moisture',
                            borderColor: '#627aac',
                            backgroundColor: 'rgba(41,73,93, 0.5)',
                            fill: true,
                            data: moistures
                        }]
                    }

                })
                .catch(err => {
                    console.log(err)
                });
        }
    }
};
</script>
<style>

#page-content-app {
  min-width: 100vw;
}

@media (min-width: 768px) {

  #page-content-app {
    min-width: 0;
    width: 100%;
  }
}

#card-device-value {
    background-color: #74992e;
    color: white;
    border-color: white;
    height: 100%;
}

#card-body-device-value {
    background-color: #8fad57;
}

#card-temperature-value {
    background-color: #cd5c5c;
    color: white;
    border-color: white;
    height: 100%;
}

#card-body-temperature-value {
    background-color: #d77c7c;
}

#card-temperature-timeseries {
    border-color: #cd5c5c;
}

#card-header-temperature-timeseries {
    background-color: #cd5c5c;
    color: white;
    border-color: white;
}

#card-moisture-value {
    background-color: #3b5998;
    color: white;
    border-color: white;
    height: 100%;
}

#card-body-moisture-value {
    background-color: #627aac;
}

#card-moisture-timeseries {
    border-color: #627aac;
}

#card-header-moisture-timeseries {
    background-color: #3b5998;
    color: white;
    border-color: white;
}
</style>
