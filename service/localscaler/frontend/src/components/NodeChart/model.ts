export class NodeChartModel {
    name: string
    cpu:{
        temperature:number
        rate:number
    }
    memory:{
        value:number
        total:number
        rate:number
    }
    storage: {
        total:number
        value:number
        rate:number
    }
    gpu?: {
        temperature:number
        rate:number
    }

    constructor() {
        this.name = 'Node Name'
        this.cpu = {
            temperature: 26,
            rate:39.7
        }
        this.memory = {
            value: 8,
            total: 16,
            rate:50
        }
        this.storage = {
            value: 100,
            total: 200,
            rate: 50
        }
    }
}