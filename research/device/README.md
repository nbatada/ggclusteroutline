# Does a change in aspect ratio change the outline?

Run `Rscript --vanilla research/device/resize.R` from the repository root with ggforce 0.5.0, ggplot2 4.0.3, svglite 2.2.2 and xml2 1.6.0. Seed 11 generates 100 points. Both scales span −4 to 4, without padding. The square and landscape SVG devices have the same height. Panel margins are zero. ggforce uses zero expansion and rounding. A base convex polygon provides a data-space control.

The four SVGs contain one inked polygon apiece. [Exported vertices](vertices.csv) are normalized by device dimensions. Changing the width from 4 to 8 inches changed the ggforce vertex count from 27 to 29. The convex control retained eight. This tests a changed aspect ratio with unconstrained Cartesian coordinates. It does not establish changes under uniform scaling or fixed-aspect resizing. Assets M0/device/{ggforce,convex}-{4x4,8x4}, revision 1.
