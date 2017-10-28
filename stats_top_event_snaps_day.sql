REM This script shows top days of wait events delta
REM Usage: @stats_top_event_snaps_day.sql instance_number date_from date_to
REM by Kamil Stawiarski (@ora600pl)

set linesize 250
set pagesize 100
alter session set nls_date_format='YYYY-MM-DD:HH24:MI';
set verify off

with v_system_class_wait as
(
select EVENT, WAIT_CLASS, TIME_WAITED_MICRO-lag(TIME_WAITED_MICRO,1,TIME_WAITED_MICRO) over (partition by event order by sys_ev.SNAP_ID) as waited_micro_diff,
       sys_ev.snap_id, TIME_WAITED_MICRO, snap.SNAP_TIME
from  STATS$SYSTEM_EVENT sys_ev, stats$snapshot snap, v$event_name e
where sys_ev.snap_id=snap.snap_id
and   snap.SNAP_TIME between to_date('&&2','YYYY-MM-DD:HH24:MI') and to_date('&&3','YYYY-MM-DD:HH24:MI')
and   wait_Class not in ('Idle','Other')
and   sys_ev.instance_number=&&1
and   snap.instance_number=&&1
and   snap.instance_number=sys_ev.instance_number
and   sys_ev.event_id=e.event_id
), v_system_rank as
(
select to_char(SNAP_TIME,'YYYY-MM-DD') as snap_day, sum(waited_micro_diff) as sm_waited_micro_diff,
       dense_rank() over (order by sum(waited_micro_diff) desc) as rnk
from v_system_class_wait
group by to_char(SNAP_TIME,'YYYY-MM-DD')
)
select sr.*
from v_system_rank sr
where rnk<=10
order by rnk
/
