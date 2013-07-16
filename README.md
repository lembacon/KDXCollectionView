# KDXCollectionView

_KDXCollectionView_ is an alternative implementation of collection view for Mac which intends to be used in order to replace _NSCollectionView_.

_KDXCollectionView_ implements a view-based cell (i.e. `KDXCollectionViewCell`) which is similar to `UITableView` and `UITableViewCell` on iOS. It is preferred to subclass `KDXCollectionViewCell` and then do your own rendering or even you can just add Cocoa controls as subviews of `KDXCollectionViewCell`.

A lot of features have already been implemented for _KDXCollectionView_ including dragging, dropping, animation, reordering, removing, hovering, selection, multiple selection, keyboard handling and etc.

An example project named `CollectionView` has been included to demonstrate a simple and common usage of _KDXCollectionView_.

# License

_KDXCollectionView_ is licensed under [MIT License](https://github.com/lembacon/KDXCollectionView/blob/master/LICENSE).
