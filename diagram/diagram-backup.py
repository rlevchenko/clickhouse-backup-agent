#-----------------------------------------------------------
# Diagram as Code | Python | https://rlevchenko.com
# PROVIDED WITHOUT WARRANTY OF ANY KIND
# ----------------------------------------------------------

# import required modules
from diagrams import Diagram, Edge, Cluster, Node

# define attributes for graphviz components
graph_attributes = {
    "fontsize": "9",
    "orientation": "portrait",
    "splines":"spline",
    "splines": "true"
}

node_attributes = {          
    "imagescale": "false",      
    "penwidth": "0",
    "fontsize": "12"
}

edge_attributes = {
    "style": "bold",
    "color": "grey",
    "fontsize": "10",
    "fontcolor": "brown"
}

with Diagram(show=False, outformat="png", graph_attr=graph_attributes, direction="TB"):
    # nodes and icons
    start_end_icon = "./custom images/start-end.png"
    decision_icon = "./custom images/decision.png"
    action_icon = "./custom images/action.png"
    out_icon = "./custom images/input-output.png"
    catch_icon = "./custom images/catch.png"
    start = Node (label="Start", image=start_end_icon, labelloc="c", height="0.4", weight="0.45", **node_attributes)
    end = Node (label="End", image=start_end_icon, labelloc="c", height="0.4", weight="0.45", **node_attributes)

    # cluster/full backup
    with Cluster("main", graph_attr=graph_attributes):
       diff_or_full = Node (label="TYPE?", image=decision_icon, height="0.7", weight="", labelloc="c", **node_attributes )
       create_full_backup = Node (label="Create FULL", labelloc="c", height="0.5", weight="4", image=action_icon, **node_attributes)
       check_upload_status = Node (label="Uploaded?", image=decision_icon, height="0.7", weight="4", labelloc="c", **node_attributes)
       check_backup_status = Node (label="Status?", image=decision_icon, height="0.7", weight="4", labelloc="c", **node_attributes)
       update_lbn = Node (label="upd last \n backup name", labelloc="c", height="0.5", weight="5", image=out_icon, **node_attributes)
       update_log_1 = Node (label="upd log", labelloc="c", height="0.5", weight="5", image=out_icon, **node_attributes)
       update_log_2 = Node (label="upd log", labelloc="c", height="0.5", weight="5", image=out_icon, **node_attributes)
    
    # cluster/diff backup
    with Cluster("diff", graph_attr=graph_attributes):
      create_diff_backup = Node (label="Create DIFF", labelloc="c", height="0.5", weight="4", image=action_icon, **node_attributes)
      update_log_diff = Node (label="Write log", labelloc="c", height="0.5", weight="5", image=out_icon, **node_attributes)

    # cluster/log
    with Cluster("log", graph_attr=graph_attributes):
      write_error = Node (label="Error", labelloc="c", height="0.5", weight="4", image=catch_icon, **node_attributes)
      error_to_log = Node (label="Write Log", labelloc="c", height="0.5", weight="4", image=out_icon, **node_attributes)
    
    # cluster/upload
    with Cluster ("upload log", graph_attr=graph_attributes):
      upload_error = Node (label="Error", labelloc="c", height="0.5", weight="4", image=catch_icon, **node_attributes)
      write_upload_error = Node (label="Write Log", labelloc="c", height="0.5", weight="4", image=out_icon, **node_attributes)
    
    # Main connections
    start - diff_or_full - Edge(xlabel="Full \n", **edge_attributes) - \
    create_full_backup - update_log_1 - \
    check_backup_status-Edge(xlabel="Created \n", **edge_attributes) - \
    check_upload_status-Edge(xlabel="YES \n", **edge_attributes) - update_log_2 - \
    update_lbn - Edge(tailport="s", headport="w", **edge_attributes ) - end
    #---------------#
    
    # Log connections
    diff_or_full - Edge(label="\n\n wrong type", tailport="e", headport="n", **edge_attributes ) - write_error 
    write_error - Edge(label="\n write to  \n log", **edge_attributes ) - error_to_log - Edge(tailport="s", headport="e") - end
    #---------------#

    # Diff connections
    diff_or_full - Edge(label="\n\n Diff", tailport="e", headport="n", **edge_attributes ) - create_diff_backup 
    create_diff_backup - Edge(label="\n update log", **edge_attributes) - update_log_diff - Edge(tailport="s", headport="e") - check_backup_status
    #---------------#

    # Backup status connections
    check_backup_status - Edge(label="\n Failed \n", tailport="e", headport="n", **edge_attributes) - upload_error
    #---------------#

    # Upload log connections
    check_upload_status - Edge(label="\n NO \n", tailport="e", headport="w", **edge_attributes ) - \
    upload_error - write_upload_error - Edge(tailport="s", headport="n") - end
    #---------------#
#-----------------------------------------------------------
# Support the project: https://diagrams.mingrammer.com/
#-----------------------------------------------------------