<template>
  <div>
    <div class="pure-g p_2 bg-gray">
      <div class="pure-u-1 pure-u-lg-1-2">
        <label class="soft">{{ labelContractsAsignedTo }}</label>
        <div class="">
          <strong class="d_block">{{ assignee }}</strong>
          <span v-if="assignee_id">
            {{ assignee_id }}
          </span>
        </div>
      </div>
    </div>

    <div class="m_t_4">
      <Table
        :items="items"
        :columns="columns"
        :routing-member="'contracts_show'"
      />
    </div>
  </div>
</template>

<script>

import { VueFiltersMixin } from "lib/shared"

import Table from "../../components/Table.vue";
import { EventBus } from "../../mixins/event_bus";
import { assigneesShowColumns } from "../../lib/config/contracts.js";

export default {
  name: 'AssigneesShow',
  components: {
    Table
  },
  mixins: [VueFiltersMixin],
  data() {
    return {
      contractsData: this.$root.$data.contractsData,
      items: [],
      columns: [],
      labelContractsAsignedTo: I18n.t('gobierto_dashboards.dashboards.contracts.contracts_assigned_to'),
    }
  },
  created() {
    EventBus.$on('refresh-summary-data', () => {
      this.contractsData = this.$root.$data.contractsData
      this.buildItems()
    });

    EventBus.$emit("refresh-active-tab");

    this.buildItems();
  },
  methods: {
    buildItems(){
      const assigneeRoutingId = this.$route.params.id;
      const contracts = this.contractsData.filter(({ assignee_routing_id }) => assignee_routing_id === assigneeRoutingId ) || [];

      this.items = contracts
      this.columns = assigneesShowColumns;

      if (contracts.length > 0) {
        const contract = contracts[0]
        this.assignee = contract.assignee
        this.assignee_id = contract.assignee_id
      }
    }
  }
}
</script>
