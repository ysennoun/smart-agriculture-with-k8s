<template>
    <div class="bg-light border-right" id="sidebar-app">
        <div class="text-dark sidebar-heading">
            <img v-bind:src="logo" width="33" height="33" class="d-inline-block align-top" alt="">
            {{title}}
        </div>
        <div id="search-device" class="text-light sidebar-heading">
            <input class="form-control" type="text" v-model="search" placeholder="Search Device" aria-label="Search">
        </div> 
        <div v-if="devices.length > 0" id="devicesNotEmpty" class="list-group list-group-flush">
            <a href="#" class="text-dark list-group-item list-group-item-action bg-light" v-for="device in filteredDevices" v-bind:key="device" @click="sendDeviceName(device)" >{{ device }}</a>
        </div>
        <div v-else id="devicesEmpty" class="list-group list-group-flush">
            <h5  class="text-light sidebar-heading"> No devices</h5>
        </div>     
    </div>
</template>
<script>
import axios from "axios";

//const httpsAgent = new https.Agent({cert: fs.readFileSync("./usercert.pem")})

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
        setValue: function(title) {
            this.title = title;
        },
        sendDeviceName(device){
            this.$emit("send-device-name", device);
        }
    },
    mounted() {
        this.setLoginPassword();
        axios
        .get(
            "https://www.themealdb.com/api/json/v1/1/categories.php"
            //config={
            //    auth: {
            //        username: 'janedoe',
            //        password: 's00pers3cret'
            //    },
            //    httpsAgent
            //}
        )
        .then(response => {
            //this.meals = response.data.categories;
            console.log(response.data.categories);
            this.devices = ["device1", "device2", "device3"];
            if (this.devices.length) {
                console.log("Devices found, emit first device: " + this.devices[0]);
                this.sendDeviceName(this.devices[0]);
            } else {
                console.log("No devices found");
            }
        })
        .catch(err => {
            console.log(err);
        });
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