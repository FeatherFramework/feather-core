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
      class="bg-gray-50 border border-gray-300 text-gray-900 text-sm rounded-md focus:ring-blue-500 focus:border-blue-500 block w-full p-2.5">
      <option v-for="language in languages" :selected="language == playerstore.lang" :key="language" :value="language">{{
        language }}</option>
    </select>
  </div>
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
