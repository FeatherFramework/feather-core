<script setup>
import LevelComp from '@/components/LevelComp.vue';
import CurrencyComp from '@/components/CurrencyComp';
import { usePlayerStore } from '@/store/player';

const store = usePlayerStore()

</script>

<template>
  <div class="home">
    <h1 class="text-center text-3xl">{{ store.first_name }} {{ store.last_name }}</h1>
    <LevelComp :current="store.xp" :goal="store.gain" :level="store.level"></LevelComp>
    <CurrencyComp type="money" :amount="store.money"></CurrencyComp>
    <CurrencyComp type="gold" :amount="store.gold"></CurrencyComp>
    <CurrencyComp type="token" :amount="store.token"></CurrencyComp>
  </div>
</template>
