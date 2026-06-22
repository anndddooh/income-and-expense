import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Plus, Trash2 } from 'lucide-react'
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import PageHeader from '@/components/PageHeader'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import {
  copyFromDefaults,
  createScenario,
  deleteScenario,
  fetchScenarios,
  type Scenario,
} from '@/api/scenarios'

export default function ScenarioList() {
  const qc = useQueryClient()
  const navigate = useNavigate()
  const [deleting, setDeleting] = useState<Scenario | null>(null)
  const [showCreate, setShowCreate] = useState(false)
  const [newName, setNewName] = useState('')
  const [newNote, setNewNote] = useState('')
  const [copyFromDefs, setCopyFromDefs] = useState(true)

  const { data: items = [], isLoading } = useQuery({
    queryKey: ['scenarios'],
    queryFn: fetchScenarios,
  })

  const delMut = useMutation({
    mutationFn: (id: number) => deleteScenario(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['scenarios'] })
      setDeleting(null)
      toast.success('削除しました')
    },
    onError: (e: unknown) => toast.error('削除失敗: ' + String(e)),
  })

  const createMut = useMutation({
    mutationFn: async () => {
      const created = await createScenario({ name: newName.trim(), note: newNote })
      if (copyFromDefs) {
        await copyFromDefaults(created.id)
      }
      return created
    },
    onSuccess: (s) => {
      qc.invalidateQueries({ queryKey: ['scenarios'] })
      setShowCreate(false)
      setNewName('')
      setNewNote('')
      navigate(`/scenarios/${s.id}`)
    },
    onError: (e: unknown) => toast.error('作成失敗: ' + String(e)),
  })

  return (
    <>
      <PageHeader
        title="シミュレーター"
        description="支出シナリオを作って月収/年収との収支を試算する"
        actions={
          <Button size="sm" onClick={() => setShowCreate(true)}>
            <Plus className="size-4" />
            新規作成
          </Button>
        }
      />

      <Card>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>名称</TableHead>
                <TableHead>備考</TableHead>
                <TableHead className="text-right">項目数</TableHead>
                <TableHead>更新</TableHead>
                <TableHead className="w-16 text-right">操作</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {isLoading && (
                <TableRow>
                  <TableCell colSpan={5} className="text-center text-muted-foreground">
                    読み込み中...
                  </TableCell>
                </TableRow>
              )}
              {!isLoading && items.length === 0 && (
                <TableRow>
                  <TableCell colSpan={5} className="text-center text-muted-foreground">
                    シナリオがありません
                  </TableCell>
                </TableRow>
              )}
              {items.map((it) => (
                <TableRow
                  key={it.id}
                  tabIndex={0}
                  className="cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                  onClick={() => navigate(`/scenarios/${it.id}`)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') navigate(`/scenarios/${it.id}`)
                  }}
                >
                  <TableCell className="font-medium">{it.name}</TableCell>
                  <TableCell className="text-sm text-muted-foreground max-w-xs truncate">
                    {it.note || '-'}
                  </TableCell>
                  <TableCell className="text-right tabular-nums">
                    {it.item_count}
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    {new Date(it.updated_at).toLocaleString()}
                  </TableCell>
                  <TableCell className="text-right">
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={(e) => {
                        e.stopPropagation()
                        setDeleting(it)
                      }}
                      aria-label="削除"
                    >
                      <Trash2 className="size-4 text-destructive" />
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <Dialog open={showCreate} onOpenChange={setShowCreate}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>新しいシナリオ</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="scenario-name">名称</Label>
              <Input
                id="scenario-name"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                placeholder="例: ジム解約パターン"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="scenario-note">備考</Label>
              <Textarea
                id="scenario-note"
                value={newNote}
                onChange={(e) => setNewNote(e.target.value)}
                placeholder="任意"
              />
            </div>
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={copyFromDefs}
                onChange={(e) => setCopyFromDefs(e.target.checked)}
              />
              現在のデフォルト支出を初期項目としてコピーする
            </label>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowCreate(false)}>
              キャンセル
            </Button>
            <Button
              disabled={!newName.trim() || createMut.isPending}
              onClick={() => createMut.mutate()}
            >
              作成
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <AlertDialog open={!!deleting} onOpenChange={(o) => !o && setDeleting(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>削除しますか?</AlertDialogTitle>
            <AlertDialogDescription>
              「{deleting?.name}」とその全項目を削除します。
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>キャンセル</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => deleting && delMut.mutate(deleting.id)}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              削除
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  )
}
