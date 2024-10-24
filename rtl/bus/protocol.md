

# Toy Bus Protocol

Toy Bus用来连接如下设备:

Master:

- Fetch
- LSU
- External Master(DMA)

Slave:

- ITCM
- DTCM
- Other Memory Map (IO/external memory)

Toy Bus采用credit based流控机制，分为req和ack两个通道。当一个请求从req通道发出时，意味着


## Signal Definition


req_vld
req_rdy
req_txnid
req_srcid
req_tgtid
req_opcode
req_addr
req_data
req_strb
req_bypass


ack_vld
ack_rdy
ack_txnid
ack_tgtid
ack_srcid
ack_opcode
ack_data
ack_bypass

## ID Mapping

| Node ID  | Node               |
|----------|--------------------|
| 0        | Fetch              |
| 1        | LSU                |
| 2        | ITCM               |
| 3        | DTCM               |
| 4        | External Mem       |
| 5        | External Master    |
| 6        | Shared Mem         |
| 7        | VLSU               |

## Connectivity

| Master/Slave | Fetch | LSU | External Master | VLSU |
| -------------|-------|-----|-----------------|------|
| ITCM         |   x   |  x  |       x         |      |
| DTCM         |   x   |  x  |       x         |      |
| External Mem |   x   |  x  |       x(?)      |      |
| Sahred Mem   |       |  x  |       x         |  x   |