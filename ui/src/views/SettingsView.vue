<script setup>
import api from '@/api';
import { useLocaleStore } from '@/store/locale';
import { usePlayerStore } from '@/store/player';
import { computed } from 'vue';
import { ref } from 'vue'

const localestore = useLocaleStore();
const playerstore = usePlayerStore();

const languages = computed(() => {
  return Object.keys(localestore.locale)
})

const selectedValue = ref(playerstore.lang)

const locale = computed(() => {
  return localestore.locale[playerstore.lang]
})

const onSelectChange = (e) => {
  selectedValue.value = e.target.value

  playerstore.updateLocale(selectedValue.value)

  api
    .post("updatelocale", {
      locale: selectedValue.value,
    })
    .catch((e) => {
      console.log(e.message);
    });
}

</script>

<template>
  <div class="about" v-if="locale">
    <h1 class="text-center text-3xl">{{ locale.ui_settings_title }}</h1>

    <h2 class="text-center text-xl mt-10">{{ locale.ui_settings_locale_title }}</h2>
    <select @change="onSelectChange" v-model="selectedValue" id="countries"
      class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-md focus:ring-red-500 focus:border-red-500 block w-full p-2.5">
      <option v-for="language in languages" :selected="language == playerstore.lang" :key="language" :value="language">{{
        language }}</option>
    </select>



  </div>
  <!-- <div>
    <h2 class="text-center text-xl mt-10">Color</h2>
      <div class="flex justify-center space-x-2">
        <input id="nativeColorPicker1" type="color" value="#6590D5" />
        <button id="burronNativeColor" type="button"
          class="inline-block rounded bg-red-600 px-6 py-2.5 text-xs font-medium uppercase leading-tight text-white shadow-md transition duration-150 ease-in-out hover:bg-red-700 hover:shadow-lg focus:bg-red-700 focus:shadow-lg focus:outline-none focus:ring-0 active:bg-red-800 active:shadow-lg">
          Save
        </button>
      </div>
  </div> -->
</template>

<!-- locale -->

<style scoped lang="scss">
h3 {
  margin: 40px 0 0;
}

ul {
  list-style-type: none;
  padding: 0;
}

li {
  display: inline-block;
  margin: 0 10px;
}
</style>
