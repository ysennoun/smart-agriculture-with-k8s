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
                    <h5 id="card-header-temperature-timeseries" class="card-header">Temperatures (°C) over time</h5>
                    <div>
                        <line-chart :chart-data="temperatureData" :height="height"></line-chart>
                    </div>
                </div>                 
            </b-col>
        </b-row>
        <b-row class="mt-2">
            <b-col>
                 <div id="card-moisture-timeseries" class="card">
                    <h5 id="card-header-moisture-timeseries" class="card-header">Moisture (%) over time</h5>
                    <div>
                        <line-chart :chart-data="moistureData" :height="height"></line-chart>
                    </div>
                </div>                 
            </b-col>
        </b-row>
    </b-container>
</template>

<script>
import LineChart from './../mixins/LineChart.js'

export default {
    components: {
        LineChart
    },
    data() {
        return {
            deviceName: null,
            temperatureData: null,
            moistureData: null,
            lastDate: null,
            lastTemperature: null,
            lastMoisture: null
        }
    },
    methods: {
        setValue: function(deviceName) {
            this.deviceName = deviceName;
            this.fillData();
        },
        fillData () {
            this.lastDate = "2020/04/07 12:34:44";
            this.lastTemperature = 18 + "°";
            this.lastMoisture = 10 + "%";
            this.temperatureData = {
                labels: ["2020-04-01 12:00:00", "2020-04-01 13:00:00", "2020-04-01 14:00:00", "2020-04-01 15:00:00", "2020-04-01 16:00:00"],
                datasets: [
                {
                    
                    label: 'Temperature',
                    borderColor: '#d77c7c',
                    backgroundColor: 'rgba(225,157,157, 0.5)',
                    fill: true,
                    data: [this.getRandomInt(), this.getRandomInt(), this.getRandomInt(), this.getRandomInt(), this.getRandomInt()]
                }]
            };
            this.moistureData = {
                labels: ["2020-04-01 12:00:00", "2020-04-01 13:00:00", "2020-04-01 14:00:00", "2020-04-01 15:00:00", "2020-04-01 16:00:00"],
                datasets: [
                {
                    
                    label: 'Moisture',
                    borderColor: '#627aac',
                    backgroundColor: 'rgba(41,73,93, 0.5)',
                    fill: true,
                    data: [this.getRandomInt(), this.getRandomInt(), this.getRandomInt(), this.getRandomInt(), this.getRandomInt()]
                }]
            }
        },
        getRandomInt () {
            return Math.floor(Math.random() * (50 - 5 + 1)) + 5
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
