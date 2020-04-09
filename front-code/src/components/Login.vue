<template>
  <div>
    <b-card>
        <h5 class="text-center">
            <img v-bind:src="logo" width="25" height="25" style="vertical-align: top;" alt="">
            <span style="vertical-align: middle;">&nbsp;Smart Agriculture</span>
            <hr>
        </h5>
        
        <b-form @submit="onSubmit" @reset="onReset">
        <b-form-group>
            <b-form-input
            id="text-login"
            v-model="form.login"
            required
            placeholder="Enter login"
            ></b-form-input>
        </b-form-group>
        <b-form-group>
            <b-input 
                type="password" 
                id="text-password" 
                v-model="form.password"
                placeholder="Enter password"
                required
                aria-describedby="password-help-block"
            ></b-input>
        </b-form-group>
        <b-button id="button-register" block type="submit">Register</b-button>
        </b-form>
    </b-card>   
  </div>
</template>

<script>
  export default {
    data() {
      return {
        logo: require('../assets/images/plant.png'),
        form: {
          login: '',
          password: ''
        }
      }
    },
    methods: {
      onSubmit(evt) {
        evt.preventDefault()
        alert(JSON.stringify(this.form))
      }
    }
  }
</script>
<style>
#button-register {
    background-color: #74992e;
    border-color: white;
    height: 100%;
}
</style>
