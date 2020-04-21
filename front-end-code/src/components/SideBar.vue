<template>
    <div class="bg-light border-right" id="sidebar-app">
        <div class="text-dark sidebar-heading">
            <img v-bind:src="logo" width="25" height="25" style="vertical-align: top;" alt="">
            {{title}}
        </div>
        <div id="search-device" class="text-light sidebar-heading">
            <input class="form-control" type="text" v-model="search" placeholder="Search Device" aria-label="Search">
        </div> 
        <div v-if="devices.length > 0" id="devicesNotEmpty" class="list-group list-group-flush">
            <a href="#" class="text-dark list-group-item list-group-item-action bg-light" v-for="device in filteredDevices" v-bind:key="device" @click="sendDeviceName(device)" >{{ device }}</a>
        </div>
        <div v-else id="devicesEmpty" class="list-group list-group-flush">
            <h5  class="text-dark sidebar-heading"> No devices</h5>
        </div> 
        <b-modal id="dialog-box-alert" hide-footer>
            <template v-slot:modal-title>
                ERROR
            </template>
            <div class="d-block text-center">
            <h3>Application can not retrieve data</h3>
            </div>
            <b-button class="mt-3" block @click="$bvModal.hide('dialog-box-alert')">Close</b-button>
        </b-modal> 
    </div>
</template>
<script>
import axios from "axios";
const https = require('https');

const BACK_END_URL = process.env.VUE_APP_BACK_END_URL

export default {
    data() {
        return {
            logo: require('../assets/images/plant.png'),
            search: '',
            devices: [],
            title: 'Smart Agriculture',
            login: null,
            password: null
        }
    },
    computed: {
      filteredDevices() {
        return this.devices.filter(device => {
          return device.toLowerCase().includes(this.search.toLowerCase())
        })
      }
    },
    methods: {
        setLoginPassword() {
            this.login = this.$store.getters.getCredentials.login,
            this.password = this.$store.getters.getCredentials.password
        },
        sendDeviceName(device){
            this.$emit("send-device-name", device);
        },
        sendAuthenticationFailed(){
            this.$store.dispatch('setAuthenticationFailed', true).then(() => {
                this.$router.push('/login')
            })
        },         
        getDevices() {
            console.log(BACK_END_URL)
            axios.get(
                    BACK_END_URL + "/devices",
                    {
                        httpsAgent: new https.Agent({rejectUnauthorized: false})
                    }
                )
                .then(response => {
                    console.log(response)
                    this.devices = response.data.rows
                    if (this.devices.length) {
                        console.log('Devices found, emit first device: ' + this.devices[0]);
                        this.sendDeviceName(this.devices[0]);
                    } else {
                        console.log('No devices found');
                    }
                })
                .catch(err => {
                    if (err.response && err.response.status == 401) {
                        console.log('Failed to login')
                        this.sendAuthenticationFailed();
                    }
                    else {
                        console.log('Error ! Application can not retrieve data')
                        this.$bvModal.show('dialog-box-alert')
                    }
                });
        }
    },
    mounted() {
        this.setLoginPassword();
        this.getDevices();
    }
}    
</script>
<style>
#sidebar-app {
  min-height: 100vh;
  -webkit-transition: margin .25s ease-out;
  -moz-transition: margin .25s ease-out;
  -o-transition: margin .25s ease-out;
  transition: margin .25s ease-out;
}

#sidebar-app .sidebar-heading {
  padding: 0.875rem 1.25rem;
  font-size: 1.2rem;
}

#sidebar-app .list-group {
  width: 15rem;
}

@media (min-width: 768px) {
  #sidebar-app {
    margin-left: 0;
  }
}
</style>