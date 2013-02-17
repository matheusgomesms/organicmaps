#include "display_list.hpp"
#include "render_context.hpp"

namespace graphics
{
  DisplayList::DisplayList(DisplayListRenderer * parent)
    : m_parent(parent),
      m_isDebugging(false)
  {}

  DisplayList::~DisplayList()
  {
    set<TextureRef>::const_iterator tit;
    for (tit = m_textures.begin();
         tit != m_textures.end();
         ++tit)
      m_parent->removeTextureRef(*tit);

    set<StorageRef>::const_iterator sit;
    for (sit = m_storages.begin();
         sit != m_storages.end();
         ++sit)
      m_parent->removeStorageRef(*sit);

    m_commands.clear();
  }

  void DisplayList::applySharpStates(shared_ptr<ApplySharpStatesCmd> const & cmd)
  {
    cmd->setIsDebugging(m_isDebugging);
    m_commands.push_back(cmd);
  }

  void DisplayList::applyBlitStates(shared_ptr<ApplyBlitStatesCmd> const & cmd)
  {
    cmd->setIsDebugging(m_isDebugging);
    m_commands.push_back(cmd);
  }

  void DisplayList::applyStates(shared_ptr<ApplyStatesCmd> const & cmd)
  {
    cmd->setIsDebugging(m_isDebugging);
    m_commands.push_back(cmd);
  }

  void DisplayList::drawGeometry(shared_ptr<DrawGeometryCmd> const & cmd)
  {
    cmd->setIsDebugging(m_isDebugging);

    shared_ptr<gl::BaseTexture> const & texture = cmd->m_texture;
    gl::Storage const & storage = cmd->m_storage;

    TextureRef tref(texture.get());

    if (texture && (m_textures.find(tref) == m_textures.end()))
    {
      m_textures.insert(tref);
      m_parent->addTextureRef(tref);
    }

    StorageRef sref(storage.m_vertices.get(), storage.m_indices.get());

    if (storage.isValid() && (m_storages.find(sref) == m_storages.end()))
    {
      m_storages.insert(sref);
      m_parent->addStorageRef(sref);
    }

    m_commands.push_back(cmd);
  }

  void DisplayList::unlockStorage(shared_ptr<UnlockStorageCmd> const & cmd)
  {
    cmd->setIsDebugging(m_isDebugging);
    m_parent->processCommand(cmd);
  }

  void DisplayList::freeStorage(shared_ptr<FreeStorageCmd> const & cmd)
  {
  }

  void DisplayList::freeTexture(shared_ptr<FreeTextureCmd> const & cmd)
  {
  }

  void DisplayList::discardStorage(shared_ptr<DiscardStorageCmd> const & cmd)
  {
  }

  void DisplayList::uploadResources(shared_ptr<UploadDataCmd> const & cmd)
  {
    cmd->setIsDebugging(m_isDebugging);
    m_parent->processCommand(cmd);
  }

  void DisplayList::addCheckPoint()
  {
    static_cast<gl::Renderer*>(m_parent)->addCheckPoint();
  }

  void DisplayList::draw(DisplayListRenderer * r,
                         math::Matrix<double, 3, 3> const & m)
  {
    math::Matrix<float, 4, 4> mv;

    /// preparing ModelView matrix

    mv(0, 0) = m(0, 0); mv(0, 1) = m(1, 0); mv(0, 2) = 0; mv(0, 3) = m(2, 0);
    mv(1, 0) = m(0, 1); mv(1, 1) = m(1, 1); mv(1, 2) = 0; mv(1, 3) = m(2, 1);
    mv(2, 0) = 0;       mv(2, 1) = 0;       mv(2, 2) = 1; mv(2, 3) = 0;
    mv(3, 0) = m(0, 2); mv(3, 1) = m(1, 2); mv(3, 2) = 0; mv(3, 3) = m(2, 2);

    r->renderContext()->setMatrix(EModelView, mv);

    /// drawing collected geometry

    if (m_isDebugging)
      LOG(LINFO, ("started DisplayList::draw"));

    for (list<shared_ptr<Command> >::const_iterator it = m_commands.begin();
         it != m_commands.end();
         ++it)
    {
      (*it)->setRenderContext(r->renderContext());
      (*it)->perform();
    }

    if (m_isDebugging)
      LOG(LINFO, ("finished DisplayList::draw"));


    r->renderContext()->setMatrix(EModelView, math::Identity<double, 4>());
  }
}
