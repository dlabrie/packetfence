<template>
  <b-tab title="SecurityEvents">
    <template v-slot:title>
      {{ $t('Security Events') }} <b-badge pill v-if="node && node.security_events && node.security_events.length > 0" variant="light" class="ml-1">{{ node.security_events.length }}</b-badge>
    </template>

    <b-table v-if="node"
      :items="node.security_events" :fields="securityEventFields" :sort-by="securityEventSortBy" :sort-desc="securityEventSortDesc" responsive show-empty sort-icon-left striped>
      <template v-slot:cell(description)="security_event">
         <router-link v-if="securityEventDescription(security_event.item.security_event_id)"
          :to="{ path: `/configuration/security_event/${security_event.item.security_event_id}` }">{{ securityEventDescription(security_event.item.security_event_id) }}</router-link>
        <router-link v-else
          :to="{ path: '/configuration/security_events' }">{{ $i18n.t('Unknown') }}</router-link>
      </template>
      <template v-slot:cell(status)="security_event">
        <b-badge pill variant="success" v-if="security_event.item.status === 'open'">{{ $t('open') }}</b-badge>
        <b-badge pill variant="danger" v-else-if="security_event.item.status === 'closed'">{{ $t('closed') }}</b-badge>
        <b-badge pill variant="warning" v-else>{{ $t('delayed') }}</b-badge>
      </template>
      <template v-slot:cell(buttons)="security_event">
        <b-button v-if="security_event.item.status === 'open'" size="sm" variant="outline-secondary" @click="onRelease(security_event.item.id)">{{ $t('Release') }}</b-button>
      </template>
      <template v-slot:empty>
        <base-table-empty :is-loading="isLoading" text="">{{ $t('No security events found') }}</base-table-empty>
      </template>
    </b-table>
    <div class="mt-3" v-if="securityEventsOptions.length > 0">
      <div class="border-top pt-3">
        <div class="d-inline-flex col-12 col-md-10 col-lg-8 col-xl-6 px-0">
          <form-security-events class="mr-1" size="sm"
            v-model="triggerSecurityEvent"
            :options="securityEventsOptions"
          />
          <b-button size="sm" variant="outline-secondary" @click="onTriggerSecurityEvent" :disabled="isLoading || !triggerSecurityEvent">{{ $t('Trigger New Security Event') }}</b-button>
        </div>
      </div>
    </div>
  </b-tab>
</template>
<script>
import {
  BaseTableEmpty
} from '@/components/new/'
import { FormSecurityEvents } from './'

const components = {
  BaseTableEmpty,
  FormSecurityEvents
}

const props = {
  id: {
    type: String
  }
}

import { computed, ref, toRefs } from '@vue/composition-api'
import { usePropsWrapper } from '@/composables/useProps'
import acl from '@/utils/acl'
import { useStore } from '../_composables/useCollection'
import { securityEventFields } from '../_config/'

const setup = (props, context) => {

  const { id } = toRefs(props)
  const { root: { $store } = {} } = context

  if (acl.$can('read', 'security_events')) {
    $store.dispatch('config/getSecurityEvents')
  }

  const node = computed(() => $store.state.$_nodes.nodes[id.value])

  const securityEventSortBy = ref('start_date')
  const securityEventSortDesc = ref(true)

  const securityEventDescription = (id) => {
    const { state: { config: { securityEvents: { [id]: { desc } = {} } = {} } = {} } = {} } = $store
    return desc
  }
  const onRelease = (security_event_id) => $store.dispatch('$_nodes/clearSecurityEventNode', { security_event_id, mac: id.value })

  // merge props w/ params in useStore methods
  const _useStore = $store => usePropsWrapper(useStore($store), props)
  const {
    isLoading,
    sortedSecurityEvents,
    applySecurityEvent
  } = _useStore($store)

  const triggerSecurityEvent = ref(null)
  const securityEventsOptions = computed(() => {
    return sortedSecurityEvents.value
      .filter(securityEvent => securityEvent.id !== 'defaults')
      .map(securityEvent => { return { text: securityEvent.desc, value: securityEvent.id } })
  })
  const onTriggerSecurityEvent = () => applySecurityEvent({ mac: id.value, security_event_id: triggerSecurityEvent.value })


  return {
    securityEventFields,

    securityEventSortBy,
    securityEventSortDesc,
    securityEventDescription,
    onRelease,

    triggerSecurityEvent,
    securityEventsOptions,
    onTriggerSecurityEvent,

    isLoading,
    node
  }
}
// @vue/component
export default {
  name: 'tab-security-events',
  inheritAttrs: false,
  components,
  props,
  setup
}
</script>